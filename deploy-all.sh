#!/usr/bin/env bash
# Script híbrido para desplegar cluster en Minikube o K3d
# NO instala herramientas, solo usa las que ya estén presentes.
# Autor: tú ;)

set -e

CLUSTER_NAME="music-cluster"
MINIKUBE_NODES=6
K3D_AGENTS=6

echo "🎵 Despliegue híbrido de cluster Kubernetes (Minikube o K3d)"
echo "-----------------------------------------------------------"

# --- Detectar qué herramientas están instaladas ---
HAS_MINIKUBE=false
HAS_K3D=false

if command -v minikube >/dev/null 2>&1; then
  HAS_MINIKUBE=true
fi

if command -v k3d >/dev/null 2>&1; then
  HAS_K3D=true
fi

# --- Verificar disponibilidad ---
if [ "$HAS_MINIKUBE" = false ] && [ "$HAS_K3D" = false ]; then
  echo "❌ No se detectó ni Minikube ni K3d en el sistema."
  echo "Por favor, instala al menos una de estas herramientas antes de ejecutar este script."
  exit 1
fi

# --- Permitir selección si hay ambas ---
if [ "$HAS_MINIKUBE" = true ] && [ "$HAS_K3D" = true ]; then
  echo "Se detectaron ambas herramientas disponibles:"
  echo "1️⃣  Minikube"
  echo "2️⃣  K3d"
  read -p "Selecciona el entorno a usar [1/2]: " seleccion
  if [ "$seleccion" = "1" ]; then
    CLUSTER_TOOL="minikube"
  else
    CLUSTER_TOOL="k3d"
  fi
elif [ "$HAS_MINIKUBE" = true ]; then
  CLUSTER_TOOL="minikube"
  echo "Usando Minikube."
else
  CLUSTER_TOOL="k3d"
  echo "Usando K3d."
fi

echo ""
echo "🌐 Herramienta seleccionada: $CLUSTER_TOOL"
echo "Cluster: $CLUSTER_NAME"
echo ""

# --- Manejo para Minikube ---
if [ "$CLUSTER_TOOL" = "minikube" ]; then
  if minikube status -p "$CLUSTER_NAME" >/dev/null 2>&1; then
    echo "⚠️  Ya existe un cluster Minikube llamado '$CLUSTER_NAME'."
    read -p "¿Deseas eliminarlo y crear uno nuevo? (s/n): " resp
    if [[ "$resp" =~ ^[sS]$|^[sS][iI]$ ]]; then
      echo "🧹 Eliminando cluster anterior..."
      minikube delete -p "$CLUSTER_NAME"
    else
      echo "✅ Manteniendo el cluster existente."
    fi
  fi

  if ! minikube status -p "$CLUSTER_NAME" >/dev/null 2>&1; then
    echo "🚀 Creando cluster Minikube con $MINIKUBE_NODES nodos..."
    minikube start --nodes "$MINIKUBE_NODES" -p "$CLUSTER_NAME"
  else
    echo "📦 Usando cluster existente."
  fi
fi

# --- Manejo para K3d ---
if [ "$CLUSTER_TOOL" = "k3d" ]; then
  if k3d cluster list | grep -q "$CLUSTER_NAME"; then
    echo "⚠️  Ya existe un cluster K3d llamado '$CLUSTER_NAME'."
    read -p "¿Deseas eliminarlo y crear uno nuevo? (s/n): " resp
    if [[ "$resp" =~ ^[sS]$|^[sS][iI]$ ]]; then
      echo "🧹 Eliminando cluster anterior..."
      k3d cluster delete "$CLUSTER_NAME"
    else
      echo "✅ Manteniendo el cluster existente."
    fi
  fi

  if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
    echo "🚀 Creando cluster K3d con $K3D_AGENTS agentes..."
    k3d cluster create "$CLUSTER_NAME" --agents "$K3D_AGENTS" --wait
  else
    echo "📦 Usando cluster existente."
  fi
fi

# --- Validar cluster activo ---
echo ""
echo "🔍 Verificando cluster..."
kubectl cluster-info
kubectl get nodes

# --- Desplegar namespaces ---
echo ""
echo "📂 Aplicando namespaces..."
for ns in namespaces/*; do
  if [ -f "$ns" ]; then
    echo "  ➜ Creando namespace desde: $ns"
    kubectl apply -f "$ns"
  fi
done

# --- Etiquetar nodos ---
echo ""
echo "🏷️  Etiquetando nodos..."
bash nodes/labels-kube.txt

# --- Aplicar taints ---
echo ""
echo "🚫 Aplicando taints..."
bash nodes/taints-kube.txt

# --- Aplicar pods ---
echo ""
echo "🎤 Aplicando pods..."
for pod in pods/*; do
  if [ -f "$pod" ]; then
    echo "  ➜ Creando pod desde: $pod"
    kubectl apply -f "$pod"
  fi
done

echo ""
echo "✅ Despliegue completado con éxito usando $CLUSTER_TOOL."
echo "Puedes verificar los pods con: kubectl get pods -A"
