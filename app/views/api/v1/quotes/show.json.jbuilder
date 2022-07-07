json.quotes @quotes do |quote|
  json.extract! quote, :quote, :author, :author_about, :tags
end
