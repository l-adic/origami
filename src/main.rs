use anyhow::Result;
use wasmer::{Instance, Module, Store, Value};
use wasmer_wasi::WasiState;

fn main() {
    println!("I'm a rust program");
    let a = format();
    match a {
        Ok(s) => {
            println!("I'm back inside a rust host program");
            println!("Formatted output: {}", s)
        }

        Err(e) => panic!("{:?}", e),
    }
}

fn format() -> Result<String> {
    // Load the WASM module from a file
    let mut store = Store::default();
    let module = Module::from_file(&store, "./ormolu/src/ormolu.wasm")?;

    // Set up WASI
    let wasi_env = WasiState::new("ormolu").finalize(&mut store)?;
    let import_object = wasi_env.import_object(&mut store, &module)?;

    // Instantiate the module with shared memory
    let instance = Instance::new(&mut store, &module, &import_object)?;
    let exports = instance.exports;
    let memory = exports.get_memory("memory")?;
    wasi_env.env.as_mut(&mut store).set_memory(memory.clone());
    let memory_buffer = memory.view(&mut store);

    // Define the functions exported by the WASM module
    let malloc_ptr = exports.get_function("mallocPtr")?;
    let malloc = exports.get_function("malloc")?;
    let format_raw = exports.get_function("formatRaw")?;
    let free = exports.get_function("free")?;

    let input = "we want to capitalize this string";
    println!("input: {}", input);

    // Allocate shared memory for input and copy input to it
    let input_len = input.len() as i32;
    let input_ptr = malloc.call(&mut store, &[input_len.into()])?[0].unwrap_i32();
    let input_bytes = input.as_bytes();
    memory_buffer.write(input_ptr as u64, input_bytes)?;

    // Call formatRaw function in the WASM module. It will return the length of the output and write
    // the output to the shared memory.
    let output_ptr_ptr = malloc_ptr.call(&mut store, &[])?[0].unwrap_i32();
    let output_len_values = format_raw.call(
        &mut store,
        &[
            Value::I32(input_ptr),
            Value::I32(input_len),
            Value::I32(output_ptr_ptr),
        ],
    )?;
    let output_len = output_len_values[0].unwrap_i32();

    // Read the output pointer from the memory
    let mut bytes = [0; 4];
    memory_buffer.read(output_ptr_ptr as u64, &mut bytes)?;
    let output_ptr = u32::from_le_bytes(bytes);

    // Assuming the output is a UTF-8 encoded string, collect it
    let mut output_bytes = vec![0; output_len as usize];
    let output = {
        memory_buffer.read(output_ptr as u64, output_bytes.as_mut_slice())?;
        String::from_utf8_lossy(&output_bytes).to_string()
    };

    // Free the allocated memory for output using the WASM module's `free` function
    free.call(&mut store, &[Value::I32(output_ptr as i32)])?;

    Ok(output)
}
