oie gente!

aqui está tudo atualizado do nosso app!

para acessar o app precisa de
-flutter + dart (vscode)
-Node.js
-Git
-para acessar o banco de dados, eu tive que instalar o Xampp

para abrir o banco de dados:

http://localhost/phpmyadmin

o arquivo do banco de dados está na basta "database" 

dependendo de onde roda o app, a URL da API muda

Web: http://localhost:3000
Android emulador: http://10.0.2.2:3000

se der erro é pq o backend nao esta conectado ao banco de dados!
na pasta backend - cria um documento de texto e escreve:

DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=cogitare_bd
DB_USER=cogitare
DB_PASSWORD=123456

PORT=3000
JWT_SECRET=cogitare_jwt_secret_2024

API_BASE_URL=http://127.0.0.1:3000/api
CORS_ORIGIN=*

***salva como ".env" e precisa estar dentro da pasta do backend***


PARA FUNCIONAR PRECISA INTELIGAR O BANCO DE DADOS COM O BACKEND!!! como fazer:

cria um terminal (sempre tem que deixar aberto!)
e escreve 

cd CogitareApp-main

dir

cd backend

npm start


pronto! depois so abrir outro terminal e rodar pelo google.




