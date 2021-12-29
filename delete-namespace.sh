#!usr/bin/env bash
##
## delete-namespace.sh
## Delete kubernetes's namespace which is stucking at terminating state
## Need kubectl v1.16 or above
## Written by Pan Xiao (C) 2021
## Licensed by MIT
##
## Changelog
## v0.1 first version done
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO 
## THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
## THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
## CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
## DEALINGS IN THE SOFTWARE.

function Delete_namespace() {
    # Check if the namespace exists
    kubectl get namespace | grep $NAMESPACE > /dev/null

    if [[ $? != 0 ]]
    then
        echo "Namespace ($NAMESPACE) does not exist, maybe it has been already deleted?"
        exit 0
    fi

    # Confirm to delete if not use -y parameter
    if [[ $YES != "1" ]]
    then
        read -p "Delete namespace ($NAMESPACE), continue? [y/n]  " yn
        case $yn in
            [Nn]* ) exit;;
            [Yy]* ) ;;
            * ) echo "Please answer y or n"
        esac
    fi

    # delete the namespace
    # https://stackoverflow.com/questions/52954174/kubernetes-namespaces-stuck-in-terminating-status
    # Thank you, Stackoverflow

    kubectl get namespace "$NAMESPACE" -o json | sed -e 's/"kubernetes"//' | kubectl replace --raw /api/v1/namespaces/$NAMESPACE/finalize -f -  > /dev/null

    if [ $? -eq 0 ]; then
        echo "Delete namespace ($NAMESPACE) successfully"
    else
        echo "Failed to delete $(NAMESPACE)"
        exit 1
    fi
}

function Help() {
    echo ""
    echo "$0  Delete a terminating namespace in Kubernetes cluster"
    echo "Usage: $0 <namespace> [-y] [-h]"
    echo -e "\t<namespace> the namespace's name that wants to delete"
    echo -e "\t-y Confirm to delete"
    echo -e "\t-h Show this help"
    exit 0
}

# Run help function when there is no argument
if [ $# -eq 0 ]; then
Help
fi

# Process arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help )
            Help
            ;;
        -y|--yes)
            YES="1" 
            ;;
        *)
            NAMESPACE="$1"
            ;;
    esac
    shift
done

# check if kubectl exists
where kubectl
if [ $? -eq 1 ]; then
    echo "kubectl does not exist, PATH please!"
    exit 1
fi
# Call the main function
Delete_namespace
