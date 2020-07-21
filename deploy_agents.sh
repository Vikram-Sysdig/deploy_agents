#/bin/bash
#function for kubectl create namespace
function kcns() {
  kubectl create namespace $1
  }

function ka() {
  kubectl -n sysdigcloud apply -f $1
  }

function broadcast() {
  WHITE='\033[1;37m'
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  PURPLE='\033[0;35m'
  NC='\033[0m'

  if [ $1 = 'w' ]; then
     echo -e "${WHITE}*******************$2*******************${NC}"
  elif [ $1 = 'r' ]; then
     echo -e "${RED}*******************$2*******************${NC}"
  elif [ $1 = 'g' ]; then
     echo -e "${GREEN}*******************$2*******************${NC}"
  elif [ $1 = 'p' ]; then
     echo -e "${PURPLE}*******************$2*******************${NC}"
  fi
  }

function kaa() {
  kubectl -n sysdig-agents apply -f $1
  }

#function for kubectl create in sysdigcloud
function kc() {
  kubectl -n sysdigcloud create $1
  }

function kca() {
  kubectl -n sysdig-agents create $1
  }


function deploy_agents() {
  broadcast 'g' "Deploying Agents"
  broadcast 'p' "Your URL is $api_url"
  broadcast 'p' "Your Access Key is: $accesskey"

  broadcast 'g' "Creating Namespace sysdig-agents"
  kcns sysdig-agents

  broadcast 'g' "Creating Secret for AccessKey"
  kc "-n sysdig-agents secret generic sysdig-agent --from-literal=access-key=$accesskey"

  broadcast 'g' "Creating Clusterrole"
  kaa agent_clusterrole.yaml

  broadcast 'g' "Creating GKE User Admin Clusterrole Binding"
  kubectl create clusterrolebinding your-user-cluster-admin-binding --clusterrole=cluster-admin --user=$1

  broadcast 'g' "Creating sysdig-agent Service Account"
  kca "serviceaccount sysdig-agent"

  broadcast 'g' "Creating ClusterRoleBinding"
  kubectl create clusterrolebinding sysdig-agent --clusterrole=sysdig-agent --serviceaccount=sysdig-agents:sysdig-agent

  broadcast 'g' "Deploying Agent Config"
  kaa agent_config.yaml

  broadcast 'g' "Deploying Agent Service"
  kaa sysdig-agent-service.yaml

  broadcast 'g' "Deploying Agents"
  kaa agent_deployment.yaml

  broadcast 'w' "It will take about two minutes for the agents to come up...."
  }

function openshift_prep() {
  broadcast 'g' "Labeling Nodes for Agent Deployment"
  oc label node --all "sysdig-agent=true" --overwrite

  broadcast 'g' "Creating project sysdig-agents"
  oc adm new-project sysdig-agents --node-selector='sysdig-agent=true'

  broadcast 'g' "Giving root and privileged access to sysdig-agent in project sysdig-agents"
  oc adm policy add-scc-to-user anyuid -n sysdig-agents -z sysdig-agent
  oc adm policy add-scc-to-user privileged -n sysdig-agents -z sysdig-agent
  }



api_url=https://doesnotmatter.com
accesskey=<INSERT ACCESS KEY>

openshift_prep
deploy_agents

