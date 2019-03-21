#!/bin/bash
#
############################
# André Luís Pizzetti
# pessetti@gmail.com
############################
# Criar pasta de log
# mkdir /var/log/bkp
# Criar um App no Slack
# https://api.slack.com/apps
############################

# Declaração de Variáveis
NOME="NOME-CLIENTE"
LOG=/var/log/bkp/`date +%Y-%m-%d`_backup-$NOME.txt
LOGFAIL1=/var/log/bkp/`date +%Y-%m-%d`_backup-$NOME-FAIL1.txt
WEBHOOK_URL="https://hooks.slack.com/services/SUA-HASH"
CHANNEL="CANAL-DEFINIDO-NO-APP"
MSG1="Backup *$NOME* está *OK!*"
MSG2="O backup do cliente *$NOME* -> *FALHOU*.\n
Acesse o Server: 172.16.0.10 e reinicie o procedimento.\n
O script fica no /root/scripts/ e existe um log desta falha neste caminho: $LOG.gz"
MSG_OK=$(echo $MSG1 | sed 's/"/\"/g' | sed "s/'/\'/g" )
MSG_FALHA=$(echo $MSG2 | sed 's/"/\"/g' | sed "s/'/\'/g" )

# Parâmetros de Configuração do Rsync
ORIGEM1="root@ip-do-cliente:/CAMINHO"
DESTINO1="/CAMINHO/"
RSYNC=`which rsync`
RSYNCOP="-avogaz"
RSYNCDET="--progress --human-readable"

# Iniciando Criação do Arquivo de Log
INICIO=`date +%d/%m/%Y-%H:%M:%S`
echo " " >> $LOG
echo " " >> $LOG
echo "| ------ ------ ------ ------ ------ ------ -----------"  >> $LOG
echo "  Sincronizacao iniciada em $INICIO" >> $LOG
# Iniciando Backup
$RSYNC $RSYNCOP $RSYNCDET $ORIGEM1 $DESTINO1 2>&1 >> $LOG
echo "$?" >> $LOGFAIL1
# Finalizando Arquivo de Log
FINAL=`date +%d/%m/%Y-%H:%M:%S`
echo "  Sincronizacao Finalizada em $FINAL" >> $LOG
echo "| ------ ------ ------ ------ ------ ------ -----------" >> $LOG
echo " " >> $LOG
echo " " >> $LOG

# Verificando se rsync finalizou com sucesso
value=$(grep -ic "0" $LOGFAIL1)
    if [ ! $value -eq 1 ]
        then
            echo "Falha no Backup" >> $LOG
        else
             echo "Backup OK" >> $LOG
    fi

# Verifica o backup para ver se está tudo OK.
verifica=$(grep -ic "Falha no Backup" $LOG)
    if [ ! $verifica -eq 1 ]
        then
            # Mandando alerta de OK no Slack
            json="{\"channel\": \"${CHANNEL}\", \"text\": \"${MSG_OK}\"}"
            curl -s -d "payload=$json" "$WEBHOOK_URL"
        else
            # Mandando alerta no Slack para Notificar Equipe da FALHA no Backup
            json="{\"channel\": \"${CHANNEL}\", \"text\": \"${MSG_FALHA}\"}"
            curl -s -d "payload=$json" "$WEBHOOK_URL"
    fi

# Compactando o Log
gzip -9 $LOG

# Apagando Logs do Servidor
rm -rf $LOGFAIL1
rm -rf $LOGMAIL
