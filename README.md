# Flakes for the anysnake2


Examples

# arbitrary STAR version
```
[flakes.star]
	url = "github:IMTMarburg/flakes?dir=STAR" #https://nixos.wiki/wiki/Flakes#Input_schema - relative paths are tricky
	rev = "4f5a72327d7add130961a9c1bd089de989b67fac" # flakes.lock tends to update unexpectedly, so we tie it down here
	follows = ["nixpkgs"]
	packages = ['star.x86_64-linux "2.7.3a"']
	# if you receive mismatchin sha-AAAAAAAAA
	# you need to copy/paste the right value (in the output) into the version map in STAR/flake.nix and commit it.
```

# copy pastable
```
[flakes.stringtie]
	url = "github:IMTMarburg/flakes?dir=StringTie" #https://nixos.wiki/wiki/Flakes#Input_schema - relative paths are tricky
	rev = "b64486e19ecdd64b913ff13d7a129fd583bcced9" # flakes.lock tends to update unexpectedly, so we tie it down here
	# follows = [] # don't follow nixpkgs, we need 21.11 for the right htslib
	packages = ['stringtie.x86_64-linux "2.0.6"']


[flakes.SRAToolkit]
	url = "github:IMTMarburg/flakes?dir=sratoolkit" 
	rev = "f2b4c6c7fc1fb80f3ab5bff5c7bb35a7bee32291" # from this repo
	# follows = ["nixpkgs"] # don't follow, we need the right so.s to wrap the stuff
	packages = ["defaultPackage.x86_64-linux"]
	
[flakes.FASTQC] 
	url = "github:IMTMarburg/flakes?dir=FASTQC"
	rev = "f2b4c6c7fc1fb80f3ab5bff5c7bb35a7bee32291" 
	follows = ["nixpkgs"] # do follow, we don't want a gazillion copies of everything
	packages = ["defaultPackage.x86_64-linux"]


[flakes.Subread]
  	url = "github:IMTMarburg/flakes?dir=Subread" 
  	rev = "d7f3f9042b0edd5caa01de4bcaad438ff35cf867"
  	follows = ["nixpkgs"]
  	packages = ["subread.x86_64-linux \"2.0.3\""

[flakes.MACS2]
	url = "github:IMTMarburg/flakes?dir=MACS2" 
	rev = "f2b4c6c7fc1fb80f3ab5bff5c7bb35a7bee32291"
	follows = ["nixpkgs"]
	packages = ["defaultPackage.x86_64-linux"]

[flakes.bowtie]
	url = "github:IMTMarburg/flakes?dir=bowtie" 
	rev = "8823bd9e51b381e83cffdde044f45b8c065fee64"
	follows = ["nixpkgs"] 
	packages = ["defaultPackage.x86_64-linux"]

[flakes.ucsc]
	url = "github:IMTMarburg/flakes?dir=ucsc_tools" 
	rev = "522c37fe6fb8dfe10745c43dba3254af3d26cb8c"
	follows = ["nixpkgs"] 
	packages = ["ucsc"]
	
[flakes.peakzilla]
	url = "github:IMTMarburg/flakes?dir=peakzilla" 
	rev = "d87511310d46c5c1e786bd4b45cad4e81a3a33b1"
	follows = ["nixpkgs"] # do follow, we don't want a gazillion copies of everything
	
[flakes.DMAP]
	url = "github:IMTMarburg/flakes?dir=DMAP" 
	rev = "d15a8840480fac549a65d87ca94ff2f564d018c3"
	follows = ["nixpkgs"] # do follow, we don't want a gazillion copies of everything
	packages = ["DMAP"]

[flakes.gdc-client]
	url = "github:IMTMarburg/flakes?dir=sratoolkit" 
	rev = "5e81f24171cf29e7f4c2b157ca55d1befb5b5f9a" # from this repo
	# follows = ["nixpkgs"] # don't follow, we need the right so.s to wrap the stuff
	packages = ["defaultPackage.x86_64-linux"]
	

```

## internal flakes

note that this one downloads the code from our own, protected internal server

```
 
[flakes.bcl2fastq]
	url = "hg+https://<enter-mbf-here>/hg/bcl2fastq"
	rev = "27e9fe9f9721088e3c9663e3359b13f3e9f5661d" 
	packages = ['bcl2fastq.x86_64-linux "v2-20-0"']
	
[flakes.mm3pseq_barcode_splitter]
	url = "hg+https://<enter-mbf-here>/hg/mm3pseq_barcode_splitter" 
	rev = "9895164e5d4a235dc78fdfbb181811231f3aeb00" # 
	packages = ['defaultPackage.x86_64-linux']


	
```

