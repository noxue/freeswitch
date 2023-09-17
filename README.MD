# 编译

```
docker build -t freeswitch:1.10.10 .
```

# 推送到docker hub

```
docker tag freeswitch:1.10.10 noxue/freeswitch:latest
docker push noxue/freeswitch:latest
```