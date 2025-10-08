#!/usr/bin/env bash
# ===============================================================
# Script híbrido para desplegar un cluster Kubernetes (Minikube o K3d)
# - Compatible con ambos entornos
# - No instala nada (seguro para Codespaces)
# - Etiquetas y taints se aplican dinámicamente según los nodos disponibles
# ===============================================================

set -e

CLUSTER_NAME="music-cluster"
MINIKUBE_NODES=6
K3D_AGENTS=6

echo "🎵 Despliegue híbrido de cluster Kubernetes"
echo "--------------------------------------------"

# --- Detectar entorno Codespaces y herramientas disponibles ---
HAS_MINIKUBE=false
HAS_K3D=false
CODESPACES_ENV=false

if [ -n "$CODESPACES" ] || [ -n "$GITHUB_CODESPACE_TOKEN" ]; then
  CODESPACES_ENV=true
fi

if command -v minikube >/dev/null 2>&1; then
  HAS_MINIKUBE=true
fi

if command -v k3d >/dev/null 2>&1; then
  HAS_K3D=true
fi

# --- Verificar disponibilidad ---
if [ "$HAS_MINIKUBE" = false ] && [ "$HAS_K3D" = false ]; then
  echo "❌ No se detectó ni Minikube ni K3d."
  echo "Instala una de ellas antes de continuar."
  exit 1
fi

# --- Seleccionar entorno ---
if [ "$CODESPACES_ENV" = true ] && [ "$HAS_K3D" = true ]; then
  echo "🧩 Detectado Codespaces → seleccionando automáticamente K3d."
  CLUSTER_TOOL="k3d"
elif [ "$HAS_MINIKUBE" = true ] && [ "$HAS_K3D" = true ]; then
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
else
  CLUSTER_TOOL="k3d"
fi

echo ""
echo "🌐 Herramienta seleccionada: $CLUSTER_TOOL"
echo "Cluster: $CLUSTER_NAME"
echo ""

# ===============================================================
# 📦 Crear cluster
# ===============================================================

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

# ===============================================================
# 🔍 Validar cluster
# ===============================================================
echo ""
echo "🔍 Verificando cluster..."
kubectl cluster-info
kubectl get nodes -o wide

# ===============================================================
# 📂 Aplicar namespaces
# ===============================================================
echo ""
echo "📂 Aplicando namespaces..."
for ns in namespaces/*; do
  if [ -f "$ns" ]; then
    echo "  ➜ Creando namespace desde: $ns"
    kubectl apply -f "$ns"
  fi
done

# ===============================================================
# 🏷️  Etiquetar y taint dinámicamente
# ===============================================================
echo ""
echo "🏷️  Aplicando etiquetas y taints dinámicamente..."

# Obtener lista de nodos
NODES=($(kubectl get nodes -o name | sed 's|node/||'))

for i in "${!NODES[@]}"; do
  NODE="${NODES[$i]}"
  echo "  ➜ Configurando nodo: $NODE"

  case "$i" in
    0)
      kubectl label node "$NODE" style=urbano --overwrite
      kubectl taint nodes "$NODE" music=perreo-intenso:NoSchedule --overwrite || true
      ;;
    1)
      kubectl label node "$NODE" style=metalero --overwrite
      kubectl taint nodes "$NODE" music=guitarra-electrica:NoSchedule --overwrite || true
      ;;
    2)
      kubectl label node "$NODE" style=electronico --overwrite
      kubectl taint nodes "$NODE" music=bass-boost:NoSchedule --overwrite || true
      ;;
    3)
      kubectl label node "$NODE" style=latino --overwrite
      kubectl taint nodes "$NODE" music=sabor-latino:NoSchedule --overwrite || true
      ;;
    4)
      kubectl label node "$NODE" style=diverso --overwrite
      kubectl taint nodes "$NODE" music=hits-globales:NoSchedule --overwrite || true
      ;;
    5)
      kubectl label node "$NODE" style=callejero --overwrite
      kubectl taint nodes "$NODE" music=rimas-urbanas:NoSchedule --overwrite || true
      ;;
    *)
      echo "  ⚙️  Nodo adicional detectado ($NODE) — sin etiquetas personalizadas."
      ;;
  esac
done

# ===============================================================
# 🎤 Aplicar pods
# ===============================================================
echo ""
echo "🎤 Aplicando pods..."
for pod in pods/*; do
  if [ -f "$pod" ]; then
    echo "  ➜ Creando pod desde: $pod"
    kubectl apply -f "$pod"
  fi
done

echo ""
echo "✅ Despliegue completado exitosamente con $CLUSTER_TOOL."
echo "Puedes verificar con: kubectl get pods -A"
