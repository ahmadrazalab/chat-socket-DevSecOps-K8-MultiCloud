# This Helm is compatible with aws only 

```bash
helm create <name>

helm install v1-rel .  # helm install <rel-name> .
helm list
helm uninstall <rel-name>
```

```bash
helm install chat-app ./chat-app
helm upgrade chat-app ./chat-app
```



# Publish Charts 
```bash
helm package <chart-directory>
```

