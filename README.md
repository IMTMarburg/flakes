# Flakes for the anysnake2


Examples

```
[flakes.SRAToolkit]
	url = "github:/IMTMarburg/flakes?dir=sratoolkit" 
	rev = "f2b4c6c7fc1fb80f3ab5bff5c7bb35a7bee32291" # from this repo
	#follows = ["nixpkgs"] # don't follow, we need the right so.s to wrap the stuff

[flakes.FASTQC]
	url = "github:/IMTMarburg/flakes?dir=FASTQC" 
	rev = "f2b4c6c7fc1fb80f3ab5bff5c7bb35a7bee32291"
	follows = ["nixpkgs"] # do follow, we don't want a gazillion copies of everything

[flakes.Subread]
	url = "github:/IMTMarburg/flakes?dir=Subread" 
	rev = "f2b4c6c7fc1fb80f3ab5bff5c7bb35a7bee32291"
	follows = ["nixpkgs"]

[flakes.MACS2]
	url = "github:/IMTMarburg/flakes?dir=MACS2" 
	rev = "f2b4c6c7fc1fb80f3ab5bff5c7bb35a7bee32291"
	follows = ["nixpkgs"]

[flakes.bowtie]
	url = "github:/IMTMarburg/flakes?dir=bowtie" 
	rev = "8823bd9e51b381e83cffdde044f45b8c065fee64"
	follows = ["nixpkgs"] 

[flakes.ucsc]
	url = "github:/IMTMarburg/flakes?dir=ucsc_tools" 
	rev = "522c37fe6fb8dfe10745c43dba3254af3d26cb8c"
	follows = ["nixpkgs"] 

[flakes.peakzilla]
	url = "github:/IMTMarburg/flakes?dir=peakzilla" 
	rev = "d87511310d46c5c1e786bd4b45cad4e81a3a33b1"
	follows = ["nixpkgs"] # do follow, we don't want a gazillion copies of everything
```
