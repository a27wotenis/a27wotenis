FROM icr.io/ibm-messaging/mq:latest

# Definir variáveis de ambiente necessárias
ENV LICENSE=accept \
    MQ_QMGR_NAME=QM1 \
    MQ_APP_USER=app \
    MQ_APP_PASSWORD=passw0rd \
    MQ_ADMIN_USER=admin \
    MQ_ADMIN_PASSWORD=passw0rd

# Criar e configurar o volume de dados
VOLUME ["/mnt/mqm"]

# Expor as portas necessárias
EXPOSE 1414 9443

# Comando de entrada para iniciar o MQ
CMD ["runmqserver"]
