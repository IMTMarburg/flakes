# Flakes for the anysnake2


Examples

# arbitrary STAR version
```
[flakes.star]
	url = "github:/IMTMarburg/flakes?dir=STAR" #https://nixos.wiki/wiki/Flakes#Input_schema - relative paths are tricky
	rev = "4f5a72327d7add130961a9c1bd089de989b67fac" # flakes.lock tends to update unexpectedly, so we tie it down here
	follows = ["nixpkgs"]
	packages = ['star.x86_64-linux "2.7.3a"']
	# if you receive mismatchin sha-AAAAAAAAA
	# you need to copy/paste the right value (in the output) into the version map in STAR/flake.nix and commit it.
```

# copy pastable
```
[flakes.stringtie]
	url = "github:/IMTMarburg/flakes?dir=StringTie" #https://nixos.wiki/wiki/Flakes#Input_schema - relative paths are tricky
	rev = "b64486e19ecdd64b913ff13d7a129fd583bcced9" # flakes.lock tends to update unexpectedly, so we tie it down here
	# follows = [] # don't follow nixpkgs, we need 21.11 for the right htslib
	packages = ['stringtie.x86_64-linux "2.0.6"']


[flakes.SRAToolkit]
	url = "github:/IMTMarburg/flakes?dir=sratoolkit" 
	rev = "f2b4c6c7fc1fb80f3ab5bff5c7bb35a7bee32291" # from this repo
	# follows = ["nixpkgs"] # don't follow, we need the right so.s to wrap the stuff
	packages = ["sratoolkit"]
	
	

[flakes.FASTQC]
	url = "github:/IMTMarburg/flakes?dir=FASTQC" 
	rev = "f2b4c6c7fc1fb80f3ab5bff5c7bb35a7bee32291"
	follows = ["nixpkgs"] # do follow, we don't want a gazillion copies of everything
	packages = ["FASTQC"]

[flakes.Subread]
	url = "github:/IMTMarburg/flakes?dir=Subread" 
	rev = "f2b4c6c7fc1fb80f3ab5bff5c7bb35a7bee32291"
	follows = ["nixpkgs"]
	packages = ["Subread"]

[flakes.MACS2]
	url = "github:/IMTMarburg/flakes?dir=MACS2" 
	rev = "f2b4c6c7fc1fb80f3ab5bff5c7bb35a7bee32291"
	follows = ["nixpkgs"]
	packages = ["defaultPackage.x86_64-linux"]

[flakes.bowtie]
	url = "github:/IMTMarburg/flakes?dir=bowtie" 
	rev = "8823bd9e51b381e83cffdde044f45b8c065fee64"
	follows = ["nixpkgs"] 
	packages = ["bowtie"]

[flakes.ucsc]
	url = "github:/IMTMarburg/flakes?dir=ucsc_tools" 
	rev = "522c37fe6fb8dfe10745c43dba3254af3d26cb8c"
	follows = ["nixpkgs"] 
	packages = ["ucsc"]
	
[flakes.peakzilla]
	url = "github:/IMTMarburg/flakes?dir=peakzilla" 
	rev = "d87511310d46c5c1e786bd4b45cad4e81a3a33b1"
	follows = ["nixpkgs"] # do follow, we don't want a gazillion copies of everything
	packages = ["peakzilla"]
	
[flakes.DMAP]
	url = "github:/IMTMarburg/flakes?dir=DMAP" 
	rev = "d15a8840480fac549a65d87ca94ff2f564d018c3"
	follows = ["nixpkgs"] # do follow, we don't want a gazillion copies of everything
	packages = ["DMAP"]

```

