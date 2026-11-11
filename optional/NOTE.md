fill it up 

install openweb ui and open terminal

#openwebui
docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data -e WEBUI_SECRET_KEY=your-secret-key --name open-webui --restart always ghcr.io/open-webui/open-webui:main

#open terminal
docker run -d --name open-terminal --restart unless-stopped -p 8000:8000 -v open-terminal:/home/user -e OPEN_TERMINAL_API_KEY=YOUR-SECRET ghcr.io/open-webui/open-terminal


connect these manually : openwebui & open terminal
 also tell to change the openterminal Secretkey first before docker deployment . 

