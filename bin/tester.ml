(* adapted from jmid/efftester *)

(* Call the generator *)
let write_prog () : string =
  let seed = Random.bits () in
  let filename = "tmp/m" ^ (string_of_int seed) ^ ".ml " in
  let _ = Sys.command ("./_build/default/bin/gen_haskell.exe -size=10 -seed=" 
    ^ (string_of_int seed) ^ " > "
    ^ filename) in
    filename
  

let run srcfile compname compcomm =
  let exefile = "~/generators/well-typed-term-generator/tmp/" ^ compname in (* hardcode the tmp directory, woops *)
  let exitcode =
    Sys.command (compcomm ^ " " ^ srcfile ^ " -o " ^ exefile) in
  (* Check that compilation was successful *)
  if exitcode <> 0
  then
    failwith (compname ^ " compilation failed with error code " ^ (string_of_int exitcode))
  else
    (* Run the compiled program *)
    let runcode = Sys.command (exefile ^ " >" ^ exefile ^ ".out 2>&1") in
    (runcode, exefile ^ ".out")
  
let  checkEqual file =
  let nrun = run file "oxcaml" "~/softwares/bin/ocamlc -w -5-26" in (* Silence warnings for partial applications *)
  let brun = run file "byte" "ocamlc -w -5-26" in         (*                      and unused variables *)
  match nrun,brun with
    | (ncode,nout), (bcode,bout) ->
      let comp = Sys.command ("diff -q " ^ nout ^ " " ^ bout ^ " > /dev/null") in
      let res = ncode = bcode && comp = 0 in
  let _ = Sys.command ("rm tmp/*.cm*") in (* cleanup compilation files *)
	if res
	then (print_string "."; flush stdout; let _ = Sys.command ("rm "^file) in res)
	else (print_string "x"; flush stdout; res)


(* No command line arguments - run N jobs*)
let generate_and_difftest () =
  let _ = Sys.command "dune build --release" in
  let rec loop i = 
    match i with
    | 0 -> ()
    | _ -> 
      let file = write_prog () in   (* Write OCaml source to file *)
      let _  = checkEqual file in
      loop (i-1)
  in 
  loop 100; (* n_jobs *)
  print_string "\n"


let () = 
  if Array.length Sys.argv > 1 
    (* then branch not working - idk what's going on*)
    then (let path = Sys.argv.(1) in
      let full_path = Unix.realpath path in
      print_endline full_path;
      let _ = checkEqual full_path in ())
    else generate_and_difftest ()


