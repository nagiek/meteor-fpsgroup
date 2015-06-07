@tickerName = (name) -> if tickers[name]? then tickers[name][i18n.getLanguage().substring(0,2)]
@currentPrice = (name) -> if currentPrices[name]? then currentPrices[name]
@currentFX = (name, base) -> if currentFXs[base]? and tickers[name]? and currentFXs[base][tickers[name].curr]? then currentFXs[base][tickers[name].curr]

tickers =
  "POT CT Equity":
    en: "Potash Corporation of Saskatchewan Inc."
    fr: "Potash Corporation of Saskatchewan Inc."
    curr: "CAD"
  "RY CT Equity":
    en: "Royal Bank of Canada"
    fr: "Banque Royale du Canada"
    curr: "CAD"
    
# Collection for autocomplete
#@Tickers = _.keys(tickers)
