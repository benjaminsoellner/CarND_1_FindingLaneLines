docker-machine start default
docker-machine env default
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
docker run -it --rm -p 8888:8888 -v $SCRIPTPATH:/src udacity/carnd-term1-starter-kit