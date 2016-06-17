# Scripts that can be used to release XAP

The main script is `scripts/release_xap.sh` it is self contained, the other scrips there only to support when something is not working and you wish to continue manually.
The configuration (should be passed as first parameter) is the name of a enviroment file that contains serios of bash exports that will be used in by the script. 

A sample configuration is in the file `scripts/setenv.sh`

First run is very slow because full git clone is done and maven m2 is empty.

After the first run it shoud take 20 min to release a new version.

## Running

From the `scripts` folder type `release_xap.sh setenv.sh`

## Configuration file explained

```bash
export BRANCH=xap-renaming-m3                     # The name of the source branch (where should we start from)
export VERSION=12.0.0-m7                          # The version that should be in the release poms.
export TAG_NAME="barak_$VERSION"                  # Once the maven install pass a tag is created and pushed for this source, this is the name of the tag.

export M2=/home/barakbo/tmp/m2                    # The location of the m2 maven, the script will delete some of the folder in this location it is best to use a dedicated folder for this script.
export WORKSPACE=/home/barakbo/tmp/workspace      # The location on the disk that the script will checkout the sources.
```

## Workflow description.

TBD


