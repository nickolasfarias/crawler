require "open-uri"
require "nokogiri"

class Api::V1::QuotesController < ApplicationController
  skip_before_action :authenticate_user!, only: :show

  def show
    #Caso a tag já tenha sido buscada AND a busca tenha retornado quotes
    if tag_searched?(params[:tag]) && search_returned_something?(params[:tag])
      set_quotes

    #Caso a tag já tenha sido buscada AND não retornou nenhuma quote, tento fazer o scraping normalmente de novo
    elsif tag_searched?(params[:tag]) && search_didnt_return_anything?(params[:tag])
      scraper(params[:tag])

      set_quotes

    #Caso a tag não tenha sido buscada, eu faço o scraping normalmente
    else
      #pra eu acompanhar quais tags eu já usei, crio uma nova tag caso ela não tenha sido procurada)
      Tag.create(name: params[:tag])

      scraper(params[:tag])

      set_quotes
    end
  end

  private

  def set_quotes
    @quotes = Quote.all.select { |quote| quote.tags[0] == params[:tag] }
  end

  #método que faz o web scraping do site de quotes
  def scraper(tag_searched)
    quotes = []
    authors = []
    authors_abouts = []
    tag_divs = []
    tags_by_div = []

    tag = tag_searched
    url = "http://quotes.toscrape.com/tag/#{tag}/"
    html_file = URI.open(url).read
    html_doc = Nokogiri::HTML(html_file)

    html_doc.search(".quote .text").each do |element|
      quotes.push(element.text.strip)
    end

    html_doc.search(".quote .author").each do |element|
      authors.push(element.text.strip)
    end

    #each-with index porque aqui eu precisei limitar os resultados ao numero de authors --> antes pegava hrefs inúteis
    html_doc.search("span a").each_with_index do |element, i|
      authors_abouts.push(element.attribute("href").value) if i < authors.count
    end

    #Aqui eu tive que desmembrar algumas coisas
    #Se eu fizesse o search direto no (".tags a") eu pegaria todos os  tags
    #O problema é que cada quote tem um array de tags, e eu estava pegando todas as tags juntas, sem distinção de quote
    #Então eu criei um array vazio chamado tag_divs lá em cima, que receberia os divs com classe "tags" de cada quote graças ao código abaixo

    html_doc.search(".tags").each do |element|
      tag_divs.push(element)
    end

    #Aí depois eu peguei esse array de divs "tags_divs" e iterei em cada div de classa tag com o each abaixo
    #Lá em cima eu criei  um array vazio chamdo tags_by_div que é um array de arrays, em que cada elemento vai ser um array com os texts dos tags relativos a um div específico.
    #Então aqui embaixo eu tenho acesso a cada div especifico usando um each
    #A cada iteração eu crio um array vazio que seria mandado pro meu array de arrays "tags_by_div" no final da iteração
    #A cada iteração eu pego o div especifico, aplico um search de anchors e um each em que cada iteração eu dou push naquele array vazio chamaado "array", conseguindo meu objetivo final, que seria separar as tags por quote no array "tags_by_div"
    tag_divs.each do |div|
      array = []

      div.search("a").each do |element|
        array.push(element.text.strip)
      end

      tags_by_div.push(array)
    end

    #Agora eu quero colocar a tag buscada como primeira tag no array para futuramente facilitar a checagem se uma tag já foi procurada
    tags_by_div.each do |array|
      tag_index = array.find_index(tag_searched)
      array[0], array[tag_index] = array[tag_index], array[0] if tag_index != 0
    end

    quotes.each_with_index do |quote, i|
      @quote = Quote.create(quote: quote, author: authors[i], author_about: "http://quotes.toscrape.com#{authors_abouts[i]}", tags: tags_by_div[i])
    end
  end

  #método que checa se uma tag já foi procurada
  def tag_searched?(tag_searched)
    Tag.all.any? { |tag| tag.name == tag_searched }
  end

  #método que checa se a busca feita anteriormente retornou algum resultado
  def search_returned_something?(tag_searched)
    Quote.all.any? { |quote| quote.tags[0] == tag_searched }
  end

  #método que checa se a busca feita anteriormente NÃO retornou algum resultado
  def search_didnt_return_anything?(tag_searched)
    Quote.all.none? { |quote| quote.tags[0] == tag_searched }
  end
end
