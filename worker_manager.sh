#!/bin/bash

BASIS_DIR="/home/hugo/basis"
REPO_DIR="$BASIS_DIR/eventos"
LOG_FILE="$BASIS_DIR/scripts/commands.log"

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

CHECK_FLAG="$BASIS_DIR/git_check.flag"
if [ -f "$CHECK_FLAG" ]; then
    echo "[$(date)] GATILHO: Verificando Git Config" >> "$LOG_FILE"
    {
        echo "--- GIT CONFIG CHECK ---"
        echo "User Name: $(/usr/bin/git config user.name)"
        echo "User Email: $(/usr/bin/git config user.email)"
    } > "$BASIS_DIR/git_check.txt"
    rm -f "$CHECK_FLAG"
fi

SET_CONFIG_FLAG="$BASIS_DIR/git_set_config.flag"
if [ -f "$SET_CONFIG_FLAG" ]; then
    echo "[$(date)] GATILHO: Configurando identidade Git..." >> "$LOG_FILE"
    
    # Lê o conteúdo da flag (espera o formato: Nome | email@exemplo.com)
    RAW_CONFIG=$(cat "$SET_CONFIG_FLAG")
    GIT_NAME=$(echo "$RAW_CONFIG" | cut -d'|' -f1 | xargs)
    GIT_EMAIL=$(echo "$RAW_CONFIG" | cut -d'|' -f2 | xargs)
    
    /usr/bin/git config --global user.name "$GIT_NAME"
    /usr/bin/git config --global user.email "$GIT_EMAIL"
    
    echo "[$(date)] SUCESSO: Git configurado como $GIT_NAME <$GIT_EMAIL>" >> "$LOG_FILE"
    rm -f "$SET_CONFIG_FLAG"
fi

CMD_FLAG="$BASIS_DIR/git_cmd.flag"
if [ -f "$CMD_FLAG" ]; then
    COMANDO=$(cat "$CMD_FLAG")
    echo "[$(date)] GATILHO: Comando Manual: $COMANDO" >> "$LOG_FILE"
    cd "$REPO_DIR" && eval $COMANDO >> "$LOG_FILE" 2>&1
    rm -f "$CMD_FLAG"
fi

STATUS_FLAG="$BASIS_DIR/git_status.flag"
if [ -f "$STATUS_FLAG" ]; then
    echo "[$(date)] GATILHO: Git Status" >> "$LOG_FILE"
    cd "$REPO_DIR" && /usr/bin/git status > "$BASIS_DIR/git_status.txt" 2>&1
    rm -f "$STATUS_FLAG"
fi

ADD_FLAG="$BASIS_DIR/git_add.flag"
if [ -f "$ADD_FLAG" ]; then
    TARGET=$(cat "$ADD_FLAG")
    [ -z "$TARGET" ] && TARGET="."
    echo "[$(date)] GATILHO: Git Add $TARGET" >> "$LOG_FILE"
    # Usamos aspas no $TARGET para evitar problemas com nomes de arquivos com espaço
    cd "$REPO_DIR" && /usr/bin/git add $TARGET >> "$LOG_FILE" 2>&1
    rm -f "$ADD_FLAG"
fi

COMMIT_FLAG="$BASIS_DIR/git_commit.flag"
if [ -f "$COMMIT_FLAG" ]; then
    MSG=$(cat "$COMMIT_FLAG")
    echo "[$(date)] GATILHO: Git Commit com mensagem: $MSG" >> "$LOG_FILE"
    cd "$REPO_DIR" && /usr/bin/git commit -m "$MSG" >> "$LOG_FILE" 2>&1
    rm -f "$COMMIT_FLAG"
fi

PUSH_FLAG="$BASIS_DIR/git_push.flag"
if [ -f "$PUSH_FLAG" ]; then
    DESTINO=$(cat "$PUSH_FLAG" | xargs) # xargs limpa espaços extras
    
    if [ -z "$DESTINO" ]; then
        echo "[$(date)] GATILHO: Git Push (Default)" >> "$LOG_FILE"
        cd "$REPO_DIR" && /usr/bin/git push >> "$LOG_FILE" 2>&1
    else
        echo "[$(date)] GATILHO: Git Push origin $DESTINO" >> "$LOG_FILE"
        cd "$REPO_DIR" && /usr/bin/git push origin "$DESTINO" >> "$LOG_FILE" 2>&1
    fi
    rm -f "$PUSH_FLAG"
fi

RESTART_FLAG="$BASIS_DIR/restart_queue.flag"
if [ -f "$RESTART_FLAG" ]; then
    echo "[$(date)] GATILHO: Restart Queue" >> "$LOG_FILE"
    # Coloque aqui o comando que você usa para reiniciar o worker do Laravel
    # ex: cd $REPO_DIR && php artisan queue:restart >> $LOG_FILE 2>&1
    rm -f "$RESTART_FLAG"
fi
