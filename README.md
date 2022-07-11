# README

## Solução adotada (meu raciocínio) e funcionamento


Eu parti do pressuposto de que criar uma API seria basicamente criar um controller específico que retorna JSON ao invés de HTML em sua view. O controller que eu gerei com esse intuito foi o "quotes_controller.rb" dentro do caminho "controllers/api/v1/".

Após isso, gerei um model chamado de "quote" que eu utilizaria para armazenar as informações extraídas do site scrapeado, preenchendo as colunas de "quote", "author", "author_about" e "tags" do referido model.

Gerei outro model de "tag" que teria só uma coluna "name" para eu acompanhar quais tags já foram pesquisadas.

Eu usei a gema "devise" em combinação com a gema "simple_token_authentication" de modo a abordar a autenticação da API (quem utilizá-la, precisa criar um usuário com "email" e "password" para gerar uma API Key que será utilizada futuramente em uma request por meio da API)

Criei um segundo controlle chamado de "base_controller" dentro da mesma pasta do "quotes_controller". Esse novo controller contém methods que geram JSONs diferentes para possibilidades de erro distintas.

Analisando o endpoint proposto pelo  desafio, cheguei à conclusão de que, para implementá-lo, eu utilizaria um method "show" a ser definido dentro controller "quotes_controller", que utilizaria o params[:tag] obtido na request.

Criei uma route para esse method show dentro do namespace de v1, que por sua vez, está dentro do namespace api.

Criei uma pasta de views para "quotes" dentro de "app/views/api/v1". Essa pasta só teria a view da action "show" do controller de "quotes".

No method "show", dentro do controller "quotes", eu utilizei a seguinte lógica:

-Primeiramente dei require no "open-uri" e no "nokogiri" para possibilitar o web scraping.

-Dentro do method show, eu considerei 3 cenários por meio de if/else: 

a) a tag já ter sido buscada e ter retornado resultados. (Eu criei dois methods separados, embaixo do "show", um para checar se a tag já foi buscada e outro para checar se a busca retornou resultados)

b) a tag já ter sido buscada, mas não retornou resultados. (Eu criei mais um method embaixo do show que checa se a busca não retornou resultados)

c) a tag não ter sido buscada.

-Em se tratando do cenário "a", como a tag já foi buscada e retornou resultados, eu simplesmente recupero os dados que foram salvos na pesquisa prévia, chamando um method que eu chamei de "set_quotes", que irá criar uma variável @quotes que eu vou usar para renderizar o JSON na view (OBS: esse method set_quotes e chamado em todos os cenários, "a", "b" e "c". A essa variável @quotes eu atribui o valor de um filtro que eu fiz no Quote.all por meio do select() que basicamente vai selecionar, dentro de todas as quotes armazendas no banco de dados, aquelas que dizem respeito à tag buscada (eu propositalemente fiz com que cada instância do model de "quote" tivesse uma propriedade "tags", que seria um array que armazenaria todas as tags relativas àquela quote específica que eu tirei do site scrapeado. Cada quote do site scrapeado tem várias tags e, muitas vezes, não só a tag pesquisada. Eu fiz com que o primeiro elemento desse array de "tags" sempre fosse a "tag" pesquisada. Assim o "Quote.all.select { |quote| quote.tags[0] == params[:tag] }" me retornaria um array com as quotes referentes à tag buscada.

-Em se tratando do cenário "b", como a tag já foi buscada, mas não retonrou resultados, a ideia seria fazer o scraping novamente para consultar o site sobre novas alterações. Aqui eu utilizo o method "scraper(params[:tag])", que é o method que efetivamente vai tratar de toda lógica de scraping. Esse method recebe como argumento a tag buscada, que viria do "params[:tag]" e cria 5 arrays vazios, que receberão a cada scraping informações referentes às quotes extraídas via scraping. O array "quotes" armazena os strings das quotes em si (as frases), o array "authors" armazena os nomes dos autores das quotes, o array "authors_abouts" recebe os links das páginas dos autores. A parte mais complicada foi a utilização dos arrays "tag_divs" e "tags_by_div", que foram criados para solucionar um problema que eu encontrei no scraping das tags, que era o fato de que caso eu scrapeasse as tags das quotes direto, eu poderia pegar todas as tags e botar em um array, mas não haveria distinção de que tags se referiam a qual quote, era só um amontoado de tags com as quais eu não poderia trabalhar. Meu intuito final era que cada array desses que eu criei tivesse o mesmo size, pois assim eu poderia iterar sobre cada um deles e criar instâncias do model quote para cada frase do site referente à tag buscada. Para resolver o problema das tags, eu utilizei o array "tag_divs" para armazenar os divs das tags, ou seja, os elementos completos, sem me aprofundar ainda em quais tags estavam em cada div. Após ter preenchido o array "tag_divs", eu iterei sobre cada elemento contido nele, de modo que a cada iteração eu criaria um array vazio, que efetivamente agruparia as tags relativas a cada quote (no final, eu mandava cada um desses arrays com as tags de cada quote para esse outro array "tags_by_div", que foi o que eu poderia de fato utilizar. Depois de scrapear cada informação e armazená-las nos arrays separadamente, eu consegui todos os dados de uma página específica, então eu iterei sobre todos esses arrays utilizando um each_with_index para criar uma instancia de quote para cada quote da página scrapeada. Por fim, chamo o method "set_quotes" novamente.

-Em se tratando do cenário "c", como a tag ainda não foi buscada, eu faço o scraping normalmente. Porém, nesse caso, antes de fazer o scraping, eu crio uma instância do model tag passando o nome da tag pesquisada, de modo armazenar no banco de dados quais tags foram efetivamente usadas para pesquisar algo.

-A view do method de "show" do quotes_controller foi criada usando o "jbuilder", já que o intuito é que ela renderize json.

-Associando as gems "sidekiq" e "sidekiq-cron" eu criei um job chamado "updatedb" que é executado de 12 em 12 horas para checar novamente no site de quotes as tags salvas no banco de dados, de modo a realizar atualizações. Como o objetivo aqui seria não duplicar as quotes já existentes, optei por apagar no (inicio de cada job) as quotes armazenadas no banco de dados e scrapear novamente o site, de modo que assim, caso haja atualizações, o scraper consegue pegar todas as quotes atualizadas e, caso não haja atuallizações, ele pega novamente as que j[a existiam antes.


## Como executar o projeto?

1°) Usar o

```
bundle install
```


2°) Rodar o seguinte comando para inicializar o MongoDB

```
sudo service mongod start
```

3°) Em uma aba do terminal usar o 

```
rails s
```


4°) Em outra aba do terminal usar o 

```
redis-server
```



5°) Em outra aba do terminal usar o 

```
sidekiq
```

6°) Usar o 

```
rails c
```

7°) Para gerar uma API key, dentro do console, criar um usuário com o seguinte comando:

```
User.create(email:"string do email", password:"string da senha")
```

8°) Após isso, você vai ter acesso a uma propriedade dentro do usuário criado chamada "authentication_token" com a API Key. Copie a API Key para usá-la no endpoint (OBS: A autenticação também irá utilizar o email da conta)

9°) Em se tratando de uma HTTP request GET, para utilizar a API, agora basta colar a seguinte url no buscador com o endpoint abaixo preenchendo a TAG buscada, o EMAIL do usuário e a API KEY atrelada ao referido usuário:

```
http://localhost:3000/api/v1/quotes/{SEARCH_TAG}?user_email={USER_EMAIL}&user_token={API_KEY}
```
