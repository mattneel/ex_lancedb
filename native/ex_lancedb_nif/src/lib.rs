use std::panic::AssertUnwindSafe;
use std::sync::{Arc, Mutex, OnceLock};

use arrow_array::types::Float32Type;
use arrow_array::{
    Array, ArrayRef, BooleanArray, FixedSizeListArray, Float32Array, Float64Array, Int64Array,
    RecordBatch, RecordBatchIterator, StringArray,
};
use arrow_schema::{DataType, Field, Schema, SchemaRef};
use futures::TryStreamExt;
use lancedb::index::vector::IvfPqIndexBuilder;
use lancedb::index::Index;
use lancedb::query::{ExecutableQuery, QueryBase};
use rustler::{Env, ResourceArc, Term};
use serde::Deserialize;
use serde_json::{Map, Value};

#[derive(Deserialize)]
struct SchemaField {
    name: String,
    #[serde(rename = "type")]
    field_type: String,
    #[serde(default)]
    dim: Option<i32>,
}

struct DbResource {
    conn: Mutex<lancedb::Connection>,
}

struct TableResource {
    table: Mutex<lancedb::Table>,
}

static RUNTIME: OnceLock<Result<tokio::runtime::Runtime, String>> = OnceLock::new();

fn runtime() -> Result<&'static tokio::runtime::Runtime, String> {
    match RUNTIME.get_or_init(|| {
        tokio::runtime::Builder::new_multi_thread()
            .enable_all()
            .build()
            .map_err(|err| format!("runtime_init_failed: {err}"))
    }) {
        Ok(runtime) => Ok(runtime),
        Err(err) => Err(err.clone()),
    }
}

fn catch_panic<T, F>(f: F) -> Result<T, String>
where
    F: FnOnce() -> Result<T, String>,
{
    match std::panic::catch_unwind(AssertUnwindSafe(f)) {
        Ok(result) => result,
        Err(payload) => Err(format!("nif_panic: {}", panic_payload_to_string(payload))),
    }
}

fn panic_payload_to_string(payload: Box<dyn std::any::Any + Send>) -> String {
    if let Some(message) = payload.downcast_ref::<String>() {
        return message.clone();
    }

    if let Some(message) = payload.downcast_ref::<&str>() {
        return message.to_string();
    }

    "unknown panic payload".to_string()
}

fn lock_conn(resource: &ResourceArc<DbResource>) -> Result<lancedb::Connection, String> {
    resource
        .conn
        .lock()
        .map_err(|_| "connection_lock_poisoned".to_string())
        .map(|conn| conn.clone())
}

fn lock_table(resource: &ResourceArc<TableResource>) -> Result<lancedb::Table, String> {
    resource
        .table
        .lock()
        .map_err(|_| "table_lock_poisoned".to_string())
        .map(|table| table.clone())
}

#[rustler::nif(schedule = "DirtyIo")]
fn connect(path: String) -> Result<ResourceArc<DbResource>, String> {
    catch_panic(|| {
        let connection = runtime()?
            .block_on(async { lancedb::connect(&path).execute().await })
            .map_err(|err| format!("connect_failed: {err}"))?;

        Ok(ResourceArc::new(DbResource {
            conn: Mutex::new(connection),
        }))
    })
}

#[rustler::nif(schedule = "DirtyIo")]
fn create_table(
    conn_ref: ResourceArc<DbResource>,
    name: String,
    schema_json: String,
) -> Result<ResourceArc<TableResource>, String> {
    catch_panic(|| {
        let conn = lock_conn(&conn_ref)?;
        let schema_fields: Vec<SchemaField> =
            serde_json::from_str(&schema_json).map_err(|err| format!("invalid_schema: {err}"))?;

        let schema = build_schema(&schema_fields)?;
        let table = runtime()?
            .block_on(async { conn.create_empty_table(name, schema).execute().await })
            .map_err(|err| format!("create_table_failed: {err}"))?;

        Ok(ResourceArc::new(TableResource {
            table: Mutex::new(table),
        }))
    })
}

#[rustler::nif(schedule = "DirtyIo")]
fn open_table(
    conn_ref: ResourceArc<DbResource>,
    name: String,
) -> Result<ResourceArc<TableResource>, String> {
    catch_panic(|| {
        let conn = lock_conn(&conn_ref)?;

        let table = runtime()?
            .block_on(async { conn.open_table(name).execute().await })
            .map_err(|err| format!("open_table_failed: {err}"))?;

        Ok(ResourceArc::new(TableResource {
            table: Mutex::new(table),
        }))
    })
}

#[rustler::nif(schedule = "DirtyIo")]
fn insert(table_ref: ResourceArc<TableResource>, records_json: String) -> Result<bool, String> {
    catch_panic(|| {
        let table = lock_table(&table_ref)?;
        let records: Vec<Value> =
            serde_json::from_str(&records_json).map_err(|err| format!("invalid_records: {err}"))?;

        if records.is_empty() {
            return Ok(true);
        }

        let schema = runtime()?
            .block_on(async { table.schema().await })
            .map_err(|err| format!("schema_read_failed: {err}"))?;

        let batch = build_record_batch_from_json(schema.clone(), &records)?;
        let iter = RecordBatchIterator::new(vec![Ok(batch)].into_iter(), schema);

        runtime()?
            .block_on(async { table.add(iter).execute().await })
            .map_err(|err| format!("insert_failed: {err}"))?;

        Ok(true)
    })
}

#[rustler::nif(schedule = "DirtyIo")]
fn search(
    table_ref: ResourceArc<TableResource>,
    embedding: Vec<f32>,
    limit: usize,
    filter: Option<String>,
) -> Result<Vec<(f64, String)>, String> {
    catch_panic(|| {
        let table = lock_table(&table_ref)?;

        let mut query = table
            .vector_search(embedding)
            .map_err(|err| format!("vector_search_build_failed: {err}"))?
            .limit(limit);

        if let Some(filter) = filter {
            query = query.only_if(filter);
        }

        let batches: Vec<RecordBatch> = runtime()?
            .block_on(async {
                let stream = query.execute().await?;
                stream.try_collect::<Vec<_>>().await
            })
            .map_err(|err| format!("search_failed: {err}"))?;

        let mut hits = Vec::new();
        for batch in batches {
            hits.extend(batch_to_hits(&batch)?);
        }

        Ok(hits)
    })
}

#[rustler::nif(schedule = "DirtyIo")]
fn create_index(
    table_ref: ResourceArc<TableResource>,
    field_name: String,
    index_type: String,
) -> Result<bool, String> {
    catch_panic(|| {
        if index_type != "ivf_pq" {
            return Err(format!("unsupported_index: {index_type}"));
        }

        let table = lock_table(&table_ref)?;

        runtime()?
            .block_on(async {
                table
                    .create_index(
                        &[field_name.as_str()],
                        Index::IvfPq(IvfPqIndexBuilder::default()),
                    )
                    .execute()
                    .await
            })
            .map_err(|err| format!("create_index_failed: {err}"))?;

        Ok(true)
    })
}

fn build_schema(schema_fields: &[SchemaField]) -> Result<SchemaRef, String> {
    let mut fields = Vec::with_capacity(schema_fields.len());

    for field in schema_fields {
        let data_type = match field.field_type.as_str() {
            "string" => DataType::Utf8,
            "integer" => DataType::Int64,
            "float" => DataType::Float64,
            "boolean" => DataType::Boolean,
            "vector" => {
                let dim = field
                    .dim
                    .ok_or_else(|| format!("vector_dim_missing_for_field:{}", field.name))?;

                DataType::FixedSizeList(
                    Arc::new(Field::new("item", DataType::Float32, true)),
                    dim,
                )
            }
            other => {
                return Err(format!("unsupported_schema_type:{}:{}", field.name, other));
            }
        };

        fields.push(Field::new(&field.name, data_type, true));
    }

    Ok(Arc::new(Schema::new(fields)))
}

fn build_record_batch_from_json(schema: SchemaRef, records: &[Value]) -> Result<RecordBatch, String> {
    let mut columns = Vec::with_capacity(schema.fields().len());

    for field in schema.fields() {
        columns.push(build_array_for_field(field.as_ref(), records)?);
    }

    RecordBatch::try_new(schema, columns).map_err(|err| format!("record_batch_build_failed: {err}"))
}

fn build_array_for_field(field: &Field, records: &[Value]) -> Result<ArrayRef, String> {
    match field.data_type() {
        DataType::Utf8 => build_utf8_array(field, records),
        DataType::Int64 => build_int64_array(field, records),
        DataType::Float64 => build_float64_array(field, records),
        DataType::Boolean => build_boolean_array(field, records),
        DataType::FixedSizeList(item, dim)
            if matches!(item.data_type(), DataType::Float32) && item.name() == "item" =>
        {
            build_vector_array(field, *dim, records)
        }
        unsupported => Err(format!(
            "unsupported_insert_type:{}:{unsupported:?}",
            field.name()
        )),
    }
}

fn build_utf8_array(field: &Field, records: &[Value]) -> Result<ArrayRef, String> {
    let mut out = Vec::with_capacity(records.len());

    for row in records {
        let value = get_field_value(row, field.name())?;
        if value.is_null() {
            require_nullable(field)?;
            out.push(None);
        } else if let Some(string) = value.as_str() {
            out.push(Some(string.to_string()));
        } else {
            return Err(type_error(field.name(), "string", value));
        }
    }

    Ok(Arc::new(StringArray::from(out)))
}

fn build_int64_array(field: &Field, records: &[Value]) -> Result<ArrayRef, String> {
    let mut out = Vec::with_capacity(records.len());

    for row in records {
        let value = get_field_value(row, field.name())?;
        if value.is_null() {
            require_nullable(field)?;
            out.push(None);
        } else if let Some(number) = value.as_i64() {
            out.push(Some(number));
        } else if let Some(number) = value.as_f64() {
            out.push(Some(number as i64));
        } else {
            return Err(type_error(field.name(), "integer", value));
        }
    }

    Ok(Arc::new(Int64Array::from(out)))
}

fn build_float64_array(field: &Field, records: &[Value]) -> Result<ArrayRef, String> {
    let mut out = Vec::with_capacity(records.len());

    for row in records {
        let value = get_field_value(row, field.name())?;
        if value.is_null() {
            require_nullable(field)?;
            out.push(None);
        } else if let Some(number) = value.as_f64() {
            out.push(Some(number));
        } else {
            return Err(type_error(field.name(), "float", value));
        }
    }

    Ok(Arc::new(Float64Array::from(out)))
}

fn build_boolean_array(field: &Field, records: &[Value]) -> Result<ArrayRef, String> {
    let mut out = Vec::with_capacity(records.len());

    for row in records {
        let value = get_field_value(row, field.name())?;
        if value.is_null() {
            require_nullable(field)?;
            out.push(None);
        } else if let Some(boolean) = value.as_bool() {
            out.push(Some(boolean));
        } else {
            return Err(type_error(field.name(), "boolean", value));
        }
    }

    Ok(Arc::new(BooleanArray::from(out)))
}

fn build_vector_array(field: &Field, dim: i32, records: &[Value]) -> Result<ArrayRef, String> {
    let mut out: Vec<Option<Vec<Option<f32>>>> = Vec::with_capacity(records.len());

    for row in records {
        let value = get_field_value(row, field.name())?;
        if value.is_null() {
            require_nullable(field)?;
            out.push(None);
            continue;
        }

        let array = value
            .as_array()
            .ok_or_else(|| type_error(field.name(), "vector", value))?;

        if array.len() != dim as usize {
            return Err(format!(
                "invalid_vector_dim:{}:expected:{}:got:{}",
                field.name(),
                dim,
                array.len()
            ));
        }

        let mut vec_values = Vec::with_capacity(dim as usize);
        for entry in array {
            if entry.is_null() {
                vec_values.push(None);
            } else if let Some(number) = entry.as_f64() {
                vec_values.push(Some(number as f32));
            } else {
                return Err(type_error(field.name(), "vector_item_float", entry));
            }
        }

        out.push(Some(vec_values));
    }

    let array = FixedSizeListArray::from_iter_primitive::<Float32Type, _, _>(out.into_iter(), dim);
    Ok(Arc::new(array))
}

fn get_field_value<'a>(row: &'a Value, field_name: &str) -> Result<&'a Value, String> {
    let object = row
        .as_object()
        .ok_or_else(|| "record_must_be_object".to_string())?;
    Ok(object.get(field_name).unwrap_or(&Value::Null))
}

fn require_nullable(field: &Field) -> Result<(), String> {
    if field.is_nullable() {
        Ok(())
    } else {
        Err(format!("required_field_missing:{}", field.name()))
    }
}

fn type_error(field_name: &str, expected: &str, got: &Value) -> String {
    format!(
        "invalid_field_type:{}:expected:{}:got:{}",
        field_name, expected, got
    )
}

fn batch_to_hits(batch: &RecordBatch) -> Result<Vec<(f64, String)>, String> {
    let mut hits = Vec::with_capacity(batch.num_rows());

    let distance_col = batch.column_by_name("_distance");

    for row_index in 0..batch.num_rows() {
        let mut record = Map::new();

        for (column_index, field) in batch.schema().fields().iter().enumerate() {
            if field.name() == "_distance" {
                continue;
            }

            let value = array_value_to_json(batch.column(column_index), row_index)?;
            record.insert(field.name().to_string(), value);
        }

        let score = if let Some(distance_array) = distance_col {
            extract_distance(distance_array, row_index)?
        } else {
            0.0
        };

        let json = serde_json::to_string(&Value::Object(record))
            .map_err(|err| format!("result_json_encode_failed: {err}"))?;

        hits.push((score, json));
    }

    Ok(hits)
}

fn extract_distance(array: &ArrayRef, row_index: usize) -> Result<f64, String> {
    if array.is_null(row_index) {
        return Ok(0.0);
    }

    if let Some(arr) = array.as_any().downcast_ref::<Float32Array>() {
        return Ok(arr.value(row_index) as f64);
    }

    if let Some(arr) = array.as_any().downcast_ref::<Float64Array>() {
        return Ok(arr.value(row_index));
    }

    Err("distance_column_type_unsupported".to_string())
}

fn array_value_to_json(array: &ArrayRef, row_index: usize) -> Result<Value, String> {
    if array.is_null(row_index) {
        return Ok(Value::Null);
    }

    if let Some(arr) = array.as_any().downcast_ref::<StringArray>() {
        return Ok(Value::String(arr.value(row_index).to_string()));
    }

    if let Some(arr) = array.as_any().downcast_ref::<Int64Array>() {
        return Ok(Value::Number(arr.value(row_index).into()));
    }

    if let Some(arr) = array.as_any().downcast_ref::<Float64Array>() {
        let number = serde_json::Number::from_f64(arr.value(row_index)).ok_or_else(|| {
            format!("non_finite_float_value_at_row:{row_index}")
        })?;
        return Ok(Value::Number(number));
    }

    if let Some(arr) = array.as_any().downcast_ref::<Float32Array>() {
        let number =
            serde_json::Number::from_f64(arr.value(row_index) as f64).ok_or_else(|| {
                format!("non_finite_float_value_at_row:{row_index}")
            })?;
        return Ok(Value::Number(number));
    }

    if let Some(arr) = array.as_any().downcast_ref::<BooleanArray>() {
        return Ok(Value::Bool(arr.value(row_index)));
    }

    if let Some(arr) = array.as_any().downcast_ref::<FixedSizeListArray>() {
        let child = arr.value(row_index);
        let child = child
            .as_any()
            .downcast_ref::<Float32Array>()
            .ok_or_else(|| "vector_child_type_unsupported".to_string())?;

        let mut out = Vec::with_capacity(child.len());
        for idx in 0..child.len() {
            if child.is_null(idx) {
                out.push(Value::Null);
            } else {
                let number = serde_json::Number::from_f64(child.value(idx) as f64)
                    .ok_or_else(|| format!("non_finite_vector_value_at_index:{idx}"))?;
                out.push(Value::Number(number));
            }
        }

        return Ok(Value::Array(out));
    }

    Err("result_column_type_unsupported".to_string())
}

#[allow(non_local_definitions)]
fn on_load(env: Env, _term: Term) -> bool {
    let _ = rustler::resource!(DbResource, env);
    let _ = rustler::resource!(TableResource, env);
    true
}

rustler::init!("Elixir.ExLanceDB.Nif", load = on_load);
