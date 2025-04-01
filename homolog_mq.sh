#!/bin/bash

# Definições
IMAGE_NAME="mq"
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="891377123998"
ECR_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
TAG="latest"

# Função para homologação local
homologar_local() {
    echo "[1/2] Construindo a imagem Docker..."
    docker build -t $IMAGE_NAME .
    if [ $? -ne 0 ]; then
        echo "Erro: Falha ao construir a imagem Docker."
        exit 1
    fi
    
    echo "[2/2] Rodando a imagem Docker..."
    docker run --volume qm1data:/mnt/mqm --publish 1414:1414 --publish 9443:9443 --detach --name $IMAGE_NAME $IMAGE_NAME
    if [ $? -ne 0 ]; then
        echo "Erro: Falha ao rodar a imagem Docker."
        exit 1
    fi
    
    echo "Homologação local concluída com sucesso."
}

# Função para subir a imagem para o ECR
subir_para_ecr() {
    echo "[1/3] Realizando login no AWS ECR..."
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL
    if [ $? -ne 0 ]; then
        echo "Erro: Falha ao realizar login no AWS ECR."
        exit 1
    fi
    
    echo "[2/3] Criando tag da imagem Docker..."
    docker tag $IMAGE_NAME:$TAG $ECR_URL/$IMAGE_NAME:$TAG
    if [ $? -ne 0 ]; then
        echo "Erro: Falha ao criar tag da imagem Docker."
        exit 1
    fi
    
    echo "[3/3] Enviando a imagem para o AWS ECR..."
    docker push $ECR_URL/$IMAGE_NAME:$TAG
    if [ $? -ne 0 ]; then
        echo "Erro: Falha ao enviar a imagem para o AWS ECR."
        exit 1
    fi
    
    echo "Imagem enviada para o AWS ECR com sucesso."
}

# Função para excluir container e imagem Docker
excluir_container() {
    echo "[1/3] Obtendo o ID do container..."
    
    # Verifica todos os containers, incluindo os parados (exited)
    CONTAINER_ID=$(docker ps -a -q --filter "name=$IMAGE_NAME")
    
    if [ -z "$CONTAINER_ID" ]; then
        echo "Nenhum container encontrado."
    else
        echo "Containers encontrados: $CONTAINER_ID"
        
        # Parar e remover todos os containers encontrados com o nome específico
        for CONTAINER in $CONTAINER_ID; do
            echo "Parando o container $CONTAINER..."
            docker stop $CONTAINER
            if [ $? -ne 0 ]; then
                echo "Erro ao parar o container $CONTAINER."
                exit 1
            fi

            echo "Removendo o container $CONTAINER..."
            docker rm $CONTAINER -f  # Força a remoção do container
            if [ $? -ne 0 ]; then
                echo "Erro ao remover o container $CONTAINER."
                exit 1
            fi

            echo "Container $CONTAINER removido com sucesso."
        done
    fi
    
    echo "[2/3] Obtendo o ID da imagem..."
    
    # Verifica a imagem correspondente ao nome
    IMAGE_ID=$(docker images -q $IMAGE_NAME)
    
    if [ -z "$IMAGE_ID" ]; then
        echo "Nenhuma imagem encontrada."
    else
        echo "Tentando remover a imagem $IMAGE_ID..."
        
        # Forçar a remoção da imagem
        docker rmi -f $IMAGE_ID
        if [ $? -ne 0 ]; then
            echo "Erro ao remover a imagem $IMAGE_ID. A imagem pode estar sendo usada por outro container."
            exit 1
        fi
        
        echo "Imagem removida com sucesso."
    fi
    
    echo "Container e imagem removidos com sucesso."
}

# Menu de opções
echo "Escolha uma opção:"
echo "1 - Apenas homologar local"
echo "2 - Subir imagem para ECR da AWS"
echo "3 - Excluir container"
echo "4 - Sair"
read -p "Opção: " opcao

case $opcao in
    1)
        homologar_local
        ;;
    2)
        subir_para_ecr
        ;;
    3)
        excluir_container
        ;;
    4)
        echo "Saindo..."
        exit 0
        ;;
    *)
        echo "Opção inválida. Saindo..."
        exit 1
        ;;
esac

