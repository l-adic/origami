use std::{collections::HashMap, env::current_dir, env, time::Instant};
use nova_scotia::{
    circom::reader::load_r1cs, create_public_params, create_recursive_circuit, FileLocation, F, S,
};
use nova_snark::{
    CompressedSNARK, PublicParams,
};
use serde_json::json;



fn run_test(circuit_filepath: String, witness_gen_filepath: String, circuit_bin_filepath: String) {
    type G1 = pasta_curves::pallas::Point;
    type G2 = pasta_curves::vesta::Point;

    println!(
        "Running test with witness generator: {} and group: {}",
        witness_gen_filepath,
        std::any::type_name::<G1>()
    );
    let iteration_count = 5;
    let root = current_dir().unwrap();

    let circuit_file = root.join(circuit_filepath);
    let circuit_bin = root.join(circuit_bin_filepath);
    let r1cs = load_r1cs::<G1, G2>(&FileLocation::PathBuf(circuit_file));
    let witness_generator_file = root.join(witness_gen_filepath);

    let mut private_inputs = Vec::new();
    for i in 0..iteration_count {
        let mut private_input = HashMap::new();
        private_input.insert("adder".to_string(), json!(i.to_string()));
        private_inputs.push(private_input);
    }

    let start_public_input = [F::<G1>::from(10), F::<G1>::from(10)];

    let pp: PublicParams<G1, G2, _, _> = create_public_params(r1cs.clone());

    println!(
        "Number of constraints per step (primary circuit): {}",
        pp.num_constraints().0
    );
    println!(
        "Number of constraints per step (secondary circuit): {}",
        pp.num_constraints().1
    );

    println!(
        "Number of variables per step (primary circuit): {}",
        pp.num_variables().0
    );
    println!(
        "Number of variables per step (secondary circuit): {}",
        pp.num_variables().1
    );

    println!("Creating a RecursiveSNARK...");
    let start = Instant::now();
    let recursive_snark = create_recursive_circuit(
        FileLocation::PathBuf(witness_generator_file),
        r1cs,
        private_inputs,
        start_public_input.to_vec(),
        &pp,
        &circuit_bin
    )
    .unwrap();
    println!("RecursiveSNARK creation took {:?}", start.elapsed());

    // TODO: empty?
    let z0_secondary = [F::<G2>::from(0)];

    // verify the recursive SNARK
    println!("Verifying a RecursiveSNARK...");
    let start = Instant::now();
    let res = recursive_snark.verify(&pp, iteration_count, &start_public_input, &z0_secondary);
    println!(
        "RecursiveSNARK::verify: {:?}, took {:?}",
        res,
        start.elapsed()
    );
    assert!(res.is_ok());

    // produce a compressed SNARK
    println!("Generating a CompressedSNARK using Spartan with IPA-PC...");
    let start = Instant::now();

    let (pk, vk) = CompressedSNARK::<_, _, _, _, S<G1>, S<G2>>::setup(&pp).unwrap();
    let res = CompressedSNARK::<_, _, _, _, S<G1>, S<G2>>::prove(&pp, &pk, &recursive_snark);
    println!(
        "CompressedSNARK::prove: {:?}, took {:?}",
        res.is_ok(),
        start.elapsed()
    );
    assert!(res.is_ok());
    let compressed_snark = res.unwrap();

    // verify the compressed SNARK
    println!("Verifying a CompressedSNARK...");
    let start = Instant::now();
    let res = compressed_snark.verify(
        &vk,
        iteration_count,
        start_public_input.to_vec(),
        z0_secondary.to_vec(),
    );
    println!(
        "CompressedSNARK::verify: {:?}, took {:?}",
        res.is_ok(),
        start.elapsed()
    );
    assert!(res.is_ok());
}


fn main() {
    let circuit_filepath : String = "adder.r1cs".to_string();

    let args: Vec<String> = env::args().collect();

    if args.len() != 2 {
        panic!("Usage: {} <mode>", args[0]);
    }

    let mode = &args[1];
    
    if mode == "wasm" {
      println!("Proving with wasm witness gen...");
      run_test(circuit_filepath, "circuit.wasm".to_string(), "./".to_string());
    } else if mode == "native" {
      println!("Proving with native witness gen ...");
      run_test(circuit_filepath.clone(), "witness-generator.sh".to_string(), "./".to_string());
    } else {
        panic!("mode must be wasm or native. Got: {}", mode);
    }

}
