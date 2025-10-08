#!/usr/bin/env bash
# Este script solo funciona en un entorno con minikube

set -e  # Detiene la ejecución si algo falla

CLUSTER_NAME="music-cluster"
NODES_COUNT=6

echo "🎵 Script de despliegue para el cluster: $CLUSTER_NAME"

# --- Verificar si el cluster ya existe ---
if minikube status -p "$CLUSTER_NAME" >/dev/null 2>&1; then
  echo "⚠️  Ya existe un cluster llamado '$CLUSTER_NAME'."
  read -p "¿Deseas eliminarlo y crear uno nuevo? (s/n): " respuesta
  case "$respuesta" in
    [sS]|[sS][iI])
      echo "🧹 Eliminando cluster anterior..."
      minikube delete -p "$CLUSTER_NAME"
      ;;
    *)
      echo "✅ Manteniendo el cluster existente."
      ;;
  esac
fi

# --- Crear cluster si no existe ---
if ! minikube status -p "$CLUSTER_NAME" >/dev/null 2>&1; then
  echo "🚀 Creando cluster con $NODES_COUNT nodos..."
  minikube start --nodes "$NODES_COUNT" -p "$CLUSTER_NAME"
else
  echo "📦 Usando cluster existente."
fi

# --- Crear namespaces ---
echo "📂 Desplegando namespaces..."
for namespace in namespaces/*; do
  if [ -f "$namespace" ]; then
    echo "  ➜ Creando namespace desde: $namespace"
    kubectl apply -f "$namespace"
  fi
done

# --- Etiquetar nodos ---
echo "🏷️  Etiquetando nodos..."
bash nodes/labels-minikube.txt

# --- Aplicar taints ---
echo "🚫 Aplicando taints a los nodos..."
bash nodes/taints-minikube.txt

# --- Crear pods ---
echo "🎤 Aplicando pods..."
for pod in pods/*; do
  if [ -f "$pod" ]; then
    echo "  ➜ Creando pod desde: $pod"
    kubectl apply -f "$pod"
  fi
done

echo ""
echo "✅ Proceso completado correctamente."
echo "Puedes verificar con: kubectl get pods --all-namespaces"
