# Kubernetes Lab Party

Pods, pods y pods!

## Información del Cluster
- **Nodos disponibles:** nodo-reggaeton, nodo-rock, nodo-techno, nodo-salsa, nodo-pop, nodo-salsa
- **Namespaces:** reggaeton, rock, techno, salsa, pop, rap

## Taints por Nodo
| Nodo | Taint Key | Taint Value | Effect |
|:------|:-----------|:-------------|:--------|
| nodo-reggaeton | music | perreo-intenso | NoSchedule |
| nodo-rock | music | guitarra-electrica | NoSchedule |
| nodo-techno | music | bass-boost | NoSchedule |
| nodo-salsa | music | sabor-latino | NoSchedule |
| nodo-pop | music | hits-globales | NoSchedule |
| nodo-rap | music | rimas-urbanas | NoSchedule |


## Labels por Nodo
| Nodo | Label Key | Label Value |
|:------|:-----------|:-------------|
| nodo-reggaeton | style | urbano |
| nodo-rock | style | metalero |
| nodo-techno | style | electronico |
| nodo-salsa | style | latino |
| nodo-pop | style | diverso |
| nodo-rap | style | callejero |


Crear el pod con las anotaciones correctas.

Los nombres de los nodos son de referencia, pueden ser diferentes en base al software empleado para emular el sistema.