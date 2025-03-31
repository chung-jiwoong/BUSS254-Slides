// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: "linux libertine",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "linux libertine",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black or heading-decoration == "underline"
           or heading-background-color != none) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)

#show: doc => article(
  title: [Financial Markets: Part II],
  subtitle: [BUSS254 Investments],
  authors: (
    ( name: [Prof.~Ji-Woong Chung],
      affiliation: [],
      email: [] ),
    ),
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)

== Lecture Outline
<lecture-outline>
- Money markets: Call, Repo, CD, CP, etc.
- #text(fill: red)[Capital markets: Bond, Equity]
- #text(fill: red)[Derivatives markets: Futures, options etc.]
- Trading mechanisms
- Investment Companies
- Reading: BKM Ch. 1 and 2, "Financial Markets in Korea" Bank of Korea (2022)

= Capital Markets
<capital-markets>

#horizontalrule

== Financial Instruments
<financial-instruments>
#block[
#box(image("img/market_Financial_Market.png"))

]

#horizontalrule

== Capital Markets
<capital-markets-1>
- Money market instruments include short-term, marketable, liquid, low-risk debt securities.

- Capital markets, in contrast, include longer term and riskier securities.

- Securities in the capital market are much more diverse than those found within the money market.

  - Bond market: longer term borrowing or debt instruments, fixed-income capital market
  - Stock market: corporate ownership is traded

#horizontalrule

== Capital Markets: Size in Korea
<capital-markets-size-in-korea>
#block[
#box(image("img/market_Capital_Market_Size.png"))

]

#horizontalrule

== Bond Market: Types
<bond-market-types>
- #strong[Government & Agency Bonds]
  - #strong[U.S. Treasury Bonds] – e.g., #strong[10-Year Treasury Note] (widely used as a benchmark rate). \
  - #strong[UK Gilts] – e.g., #strong[30-Year Gilt] (long-term government bond). \
  - #strong[Korea Treasury Bonds (KTBs)] – e.g., #strong[3-Year KTB] (actively traded in Korean markets). \
  - #strong[Foreign Exchange Stabilization Fund Bonds] – Issued by Korea to #strong[manage FX reserves];. \
- #strong[Municipal Bonds]
  - #strong[New York City General Obligation Bonds] – Funds public projects like schools, bridges. \
- #strong[Corporate Bonds]
  - #strong[Apple Inc.~Bonds] – Issued for corporate expansion and share buybacks. \
  - #strong[Samsung Electronics Bonds] – Used for R&D and investment in semiconductor production. \
- #strong[Financial Bonds]
  - #strong[JP Morgan Chase Bonds] – Bank-issued bonds for liquidity management. \
  - #strong[Korea Development Bank (KDB) Bonds] – Supports industrial development. \
- #strong[Special Bonds]
  - #strong[Monetary Stabilization Bonds (MSBs)] – Issued by #strong[Bank of Korea (BOK)] for monetary policy. \
  - #strong[KEPCO Bonds] – Issued by #strong[Korea Electric Power Corporation] to finance energy projects.

== Bond Market: Types
<bond-market-types-1>
- #strong[By Market]
  - #strong[Domestic Bonds] – #strong[Japan Government Bonds (JGBs)] issued in yen. \
  - #strong[International Bonds]
    - #strong[Eurobonds] – #strong[Toyota Eurobond] (denominated in USD, issued outside Japan). \
    - #strong[Foreign Bonds] – #strong[Samurai Bonds] (issued in Japan by foreign entities).
- #strong[By Security & Guarantee]
  - #strong[Secured Bonds] – #strong[Mortgage-Backed Securities (MBS)] (e.g., #strong[Fannie Mae Bonds];). \
  - #strong[Unsecured Bonds] – #strong[Tesla Senior Unsecured Notes];. \
  - #strong[Guaranteed Bonds] – #strong[Korea Deposit Insurance Corporation (KDIC) Bonds];.
- #strong[By Interest Rate & Structure]
  - #strong[Fixed-Rate Bonds] – #strong[10-Year U.S. Treasury Bond] (pays a fixed yield). \
  - #strong[Floating-Rate Bonds] – #strong[SOFR-linked Corporate Bonds];. \
  - #strong[Zero-Coupon Bonds] – #strong[STRIPS (Separate Trading of Registered Interest and Principal Securities)];. \
  - #strong[Coupon Bonds] – #strong[Coca-Cola Corporate Bonds] (pays semi-annual interest). \
  - #strong[Convertible Bonds] – #strong[Tesla Convertible Bonds] (convertible into Tesla stock). \
  - #strong[Bonds with Warrants] – #strong[Alibaba Bonds with Stock Warrants];. \
  - #strong[Exchangeable Bonds] – #strong[LVMH Exchangeable Bonds] (convertible into shares of its subsidiary).

#horizontalrule

== Bond Market: Monetary Stabilization Bonds
<bond-market-monetary-stabilization-bonds>
- Issued by BOK to adjust monetary liquidity
- One of the major tools for open market operations
- 91-day (discount), 1-, 2-, and 3-year (coupon)

#block[
#box(image("img/market_MSB_balance.png"))

]

#horizontalrule

== Bond Market: Asset-Backed Securities
<bond-market-asset-backed-securities>
- Securities created by pooling together typically #emph[illiquid] assets and then "securitizing" them into marketable securities.

- #strong[Underlying Asset Pools:] Common types of assets used to create ABS include:

  - #strong[Mortgages (MBS):] Home loans
  - #strong[Loans (CLO):] Corporate loans
  - #strong[Bonds (CBO):] Corporate bonds
  - #strong[Credit Card Receivables (CARD):] Outstanding balances on credit cards

- Transfer of ownership of the underlying assets from the asset originator to a special purpose company/vehicle

- #strong[2008 Financial Crisis Connection:] Complex and poorly understood ABS, particularly those backed by subprime mortgages, played a significant role in the 2008 financial crisis. This highlighted risks associated with ABS, including:

  - #strong[Complexity:] Difficult to assess the true risk of ABS due to their intricate structure.
  - #strong[Opacity:] Lack of transparency in the underlying asset pools.
  - #strong[Incentive Problems:] Originators had weak incentives to properly vet the loans.

#horizontalrule

== Bond Market (cont’d)
<bond-market-contd>
#block[
#box(image("img/market_Securitization.png"))

]
- #strong[Securitization Process] involves:

  - #strong[Asset Transfer:] Transferring ownership of the underlying assets from the originator (e.g., a bank) to a Special Purpose Vehicle (SPV) or company.
  - #strong[SPV:] Isolates the assets, bankruptcy remoteness, and allows the SPV to issue new securities backed by those assets.
  - #strong[Creating Securities:] SPV creates and sells new securities (the ABS) to investors. These securities derive their value from the cash flows generated by the underlying assets.

#horizontalrule

== Bond Market: Covered Bonds & Foreign Exchange Stabilization Fund Bond
<bond-market-covered-bonds-foreign-exchange-stabilization-fund-bond>
#strong[Covered Bonds]

- #strong[Similar to Asset-Backed Securities (ABS)] but with key differences:
  - #strong[Cover pool remains on the issuer’s balance sheet] (unlike ABS, where assets are transferred to an SPV). \
  - Investors have #strong[dual recourse];:
    - First, to the issuing financial institution. \
    - Second, to the #strong[underlying asset pool (cover pool)] in case of default. \
- Functions as a #strong[corporate bond] issued by financial institutions, with an #strong[extra layer of protection] for investors. \
- #strong[More common in Europe];, especially in #strong[Germany (Pfandbriefe)];, but also in #strong[Denmark, France, and Spain];.

#strong[Foreign Exchange Stabilization Fund Bonds (FESFBs)]

- #strong[Foreign currency-denominated bonds] issued by the #strong[Korean government] in #strong[international bond markets];. \
- #strong[Objectives:]
  - Establishes #strong[benchmark interest rates] for Korean bonds in global markets. \
  - #strong[Supports foreign exchange stability] by securing external financing. \
  - Helps manage #strong[Korea’s foreign exchange reserves] effectively. \
- Typically issued in #strong[USD, EUR, or JPY];, providing a reference for Korean corporate and sovereign issuers abroad.

#horizontalrule

== Bond Market: Statistics in Korea
<bond-market-statistics-in-korea>
#block[
#box(image("img/market_Korea_Govnt_Bonds1.png")) #box(image("img/market_Korea_Govnt_Bonds2.png"))

Source: #link("https://ktb.moef.go.kr/ntndbtWtp.do")[Ministry of Economy and Finance]

]

#horizontalrule

== Bond Markets: Global
<bond-markets-global>
#block[
#box(image("img/market_Global_Bond_Issue.png"))

Source: Capital Market Factbook - SIFMA, 2024

]

#horizontalrule

== Bond Markets: Global (cont’d)
<bond-markets-global-contd>
#block[
#box(image("img/market_Global_Bond_Outstanding.png"))

Source: Capital Market Factbook - SIFMA, 2024

]

#horizontalrule

== Bond Markets: Global (cont’d)
<bond-markets-global-contd-1>
#block[
#box(image("img/market_Debt_Financing.png"))

Source: Capital Market Factbook - SIFMA, 2024

]

#horizontalrule

== Stock Markets
<stock-markets>
#strong[Types of Stocks]

- #strong[Common Stocks]
  - Represent #strong[ownership in a company] with a #strong[claim on earnings and assets];. \
  - Shareholders have #strong[voting rights] in corporate decisions.
- #strong[Preferred Stocks]
  - Receive #strong[dividends before common stockholders];. \
  - Typically have #strong[limited or no voting rights];. \
  - May include #strong[special features];:
    - #strong[Redeemable Preferred Shares] – Can be converted to #strong[cash at a set price];. \
    - #strong[Convertible Preferred Shares] – Can be converted into #strong[common stock];.
- #strong[Residual Claims in Liquidation]
  - In case of #strong[bankruptcy];, common and preferred stockholders receive #strong[remaining assets only after debt holders are paid];.

#strong[Share Classes & Voting Rights]

- Companies can issue #strong[multiple share classes] with #strong[different voting rights or privileges];. \
- Used to #strong[preserve control by founders or key shareholders];. \
- #strong[Introduced in Korea in November 2023];, allowing companies to issue #strong[dual-class shares];.
  - Example: #strong[Google (Alphabet) Class A, B, and C shares] with varying voting rights.

#strong[Stock Market Trading & Issuance]

- #strong[Primary Market] (New Issuance)
  - #strong[Private Placements] – Shares sold to select investors (e.g., institutions, venture capital). \
  - #strong[Initial Public Offering (IPO)] – A company’s first public stock sale. \
  - #strong[Seasoned Equity Offering (SEO)] – Additional stock issuance by a publicly traded company.
- #strong[Secondary Market] (Trading)
  - Stocks are #strong[bought and sold on exchanges or OTC markets];. \
  - Major stock exchanges:
    - #strong[New York Stock Exchange (NYSE)];, #strong[NASDAQ];, #strong[Korea Exchange (KRX)];. \
    - OTC markets handle #strong[smaller or less regulated securities];.

#horizontalrule

== Stock Markets: Exchanges
<stock-markets-exchanges>
=== Korea Exchange (KRX)
<korea-exchange-krx>
- #strong[KOSPI (Korea Composite Stock Price Index)];: Established in #strong[1956];, serving as the #strong[main board] for #strong[large-cap companies];.
- #strong[KOSDAQ (Korea Securities Dealers Automated Quotations)];: Launched in #strong[1996];, focusing on #strong[technology and growth-oriented firms];.
- #strong[KONEX (Korea New Exchange)];: Introduced in #strong[2013] to facilitate funding for #strong[Small and Medium Enterprises (SMEs)];.
- #strong[K-OTC (Korea Over-the-Counter Market)];: Started in #strong[2014];, providing a platform for trading #strong[unlisted stocks];.

=== Nextrade (NXT) – Korea’s New Alternative Exchange (2025)
<nextrade-nxt-koreas-new-alternative-exchange-2025>
- #strong[Extended Trading Hours];: #strong[8:00 a.m. – 8:00 p.m.] (KRX: 9:00 a.m. – 3:30 p.m.). \
- #strong[Lower Transaction Fees];: #strong[20–40% cheaper] than KRX. \
- #strong[Smart Order Routing (SOR)];: Brokers auto-direct orders for best prices. \
- #strong[New Order Types];: Includes #strong[mid-price orders] and #strong[stop-limit orders];.

#horizontalrule

== Stock Markets: Trends
<stock-markets-trends>
#block[
#box(image("img/market_KOSPI.png")) #box(image("img/market_KOSDAQ.png"))

]

#horizontalrule

== Stock Markets: Performance
<stock-markets-performance>

#horizontalrule

== Stock Markets: Global Issuance
<stock-markets-global-issuance>
#block[
#box(image("img/market_Global_Equity_Issue.png"))

Source: Capital Market Factbook - SIFMA, 2024

]
== Stock Markets: Market Capitalization
<stock-markets-market-capitalization>
#block[
#box(image("img/market_Global_Equity_Cap.png"))

Source: Capital Market Factbook - SIFMA, 2024

]
== Stock Markets: Financing by Country
<stock-markets-financing-by-country>
#block[
#box(image("img/market_Financing_by_Country.png"))

Source: Capital Market Factbook - SIFMA, 2023

]
== Stock Markets: Cross-listing
<stock-markets-cross-listing>
- The practice of listing a company’s equity shares on one or more foreign exchanges.

- The number of cross-listed firms has grown rapidly, now representing about 10% of publicly traded companies worldwide.

- The primary motivation for cross-listing is to reduce the firm’s cost of capital by increasing investor access and improving liquidity.

- Types of Cross-listing

  + Direct Listing
    - A company lists its shares on a foreign exchange without issuing new equity.
    - Requires compliance with the listing regulations of the foreign exchange.
  + Depositary Receipts (DRs)
    - A financial instrument representing shares of a foreign company, held in custody by a domestic bank.
    - Enables investors to trade foreign stocks more easily on their home market.

- Types of Depositary Receipts: American Depositary Receipts (ADRs), European Depositary Receipts (EDRs), Global Depositary Receipts (GDRs), Indian Depository Receipts (IDRs)

#horizontalrule

== Stock Market Indices
<stock-market-indices>
- A hypothetical portfolio representing a segment of the financial market.

- Used as a barometer of market performance and an investment benchmark.

- Key Uses of Stock Market Indices:

  - Market performance measurement: Indicates overall stock market trends.
  - Performance benchmarking: Compares the returns of money managers and funds.
  - Passive investment strategies: Forms the basis for index funds, ETFs, and passive portfolio management.
  - Foundation for derivatives: Many futures, options, and swaps are based on stock indices.

- Types of Stock Market Indices: Indices vary based on:

  - Market representation: Sector-based, regional, size-based indices, etc.
  - Weighting schemes: Market-cap weighted, price-weighted, equal-weighted, etc.

#horizontalrule

== Stock Market Indices (cont’d)
<stock-market-indices-contd>
- Price-Weighted Index
  - Each company’s stock is weighted by its price per share, and the index is an average of the share prices of all the companies.
  - Greater weight is given to stocks with higher prices.
  - Initially, this is similar to investing in equal numbers of shares of each stock, but weighting changes over time due to stock splits and price fluctuations.
  - Examples: DJIA, Nikkei 225.
- Market Value-Weighted Index
  - Individual components are weighted according to their relative total market capitalization. \
  - Most indices use free-floating market capitalization, meaning they consider only shares available for public trading rather than total market capitalization.
  - Companies with higher market capitalization receive a higher weighting in the index.
  - Investing in proportion to market value (buy-and-hold).
  - Examples: S&P 500, NASDAQ, KOSPI, KOSDAQ.
- Equal-Weighted Index
  - Each stock is assigned an equal weight, meaning the index value is the simple arithmetic average of stock returns.
  - Investing equal dollar values in each stock requires continuous rebalancing.
  - Examples: S&P 500 Equal Weight, MSCI Equal Weight.

#horizontalrule

== Stock Market Indices: Example
<stock-market-indices-example>
#table(
  columns: (9.86%, 7.04%, 7.04%, 21.13%, 21.13%, 16.9%, 16.9%),
  align: (auto,auto,auto,auto,auto,auto,auto,),
  table.header([Stock], [P1], [Q1], [P2 (No split)], [Q2 (No split)], [P2 (Split)], [Q2 (Split)],),
  table.hline(),
  [A], [$10$], [$40$], [$15$], [$40$], [$15$], [40\$],
  [B], [$50$], [$80$], [$50$], [$80$], [$25$], [160\$],
  [C], [$140$], [$50$], [$150$], [$50$], [$150$], [50\$],
)
#strong[#emph[Price-Weighted Index];]

- #strong[Day 1:] $(10 + 50 + 140) \/ 3 = 66.67$
- #strong[Day 2 - No split:] $(15 + 50 + 150) \/ 3 = 71.67$
- #strong[Day 2 - Split:]
  - Find $d$ such that $(10 + 25 + 140) \/ d = 66.67$, solving for $d$ gives $d = 2.625$.
  - Then, $(15 + 25 + 150) \/ 2.625 = 72.38$
- $d$ is called the #strong[Dow Divisor];, which is continuously adjusted for corporate actions such as dividend payments and stock splits.
- As of December 2021, the divisor for DJIA is $0.15172752595384$.
- With a stock split, the change in the index does #strong[not] represent the actual investment outcome of holding one share of each stock: $72.38 \/ 66.67 = 8.57 % eq.not 71.67 \/ 66.67 = 7.5 %$

#horizontalrule

== Stock Market Indices: Example (cont’d)
<stock-market-indices-example-contd>
#table(
  columns: (9.86%, 7.04%, 7.04%, 21.13%, 21.13%, 16.9%, 16.9%),
  align: (auto,auto,auto,auto,auto,auto,auto,),
  table.header([Stock], [P1], [Q1], [P2 (No split)], [Q2 (No split)], [P2 (Split)], [Q2 (Split)],),
  table.hline(),
  [A], [$10$], [$40$], [$15$], [$40$], [$15$], [40\$],
  [B], [$50$], [$80$], [$50$], [$80$], [$25$], [160\$],
  [C], [$140$], [$50$], [$150$], [$50$], [$150$], [50\$],
)
#strong[#emph[Market Value-Weighted Index];]

- #strong[Day 1:] $(400 + 4 , 000 + 7 , 000) = 11 , 400$
- #strong[Day 2:] $(600 + 4 , 000 + 7 , 500) = 12 , 100$
  - Using #strong[Day 1 as the base year] (e.g., setting it equal to 100)
  - #strong[Day 2 index:] $12 , 100 \/ 11 , 400 times 100 = 106.14$
- If you invest in proportion to market value (i.e., 3.50% in A, 35.07% in B, and 61.40% in C), the return is: $3.50 % times (600 \/ 400 - 1) + 35.07 % times (4 , 000 \/ 4 , 000 - 1) + 61.40 % times (7 , 500 \/ 7 , 000 - 1) = 6.14 %$

#horizontalrule

== Stock Market Indices (cont’d)
<stock-market-indices-contd-1>
#table(
  columns: (9.86%, 7.04%, 7.04%, 21.13%, 21.13%, 16.9%, 16.9%),
  align: (auto,auto,auto,auto,auto,auto,auto,),
  table.header([Stock], [P1], [Q1], [P2 (No split)], [Q2 (No split)], [P2 (Split)], [Q2 (Split)],),
  table.hline(),
  [A], [$10$], [$40$], [$15$], [$40$], [$15$], [40\$],
  [B], [$50$], [$80$], [$50$], [$80$], [$25$], [160\$],
  [C], [$140$], [$50$], [$150$], [$50$], [$150$], [50\$],
)
#strong[#emph[Equal-Weighted Index];]

- #strong[Day 1:] Base year, set it equal to 100.

- #strong[Day 2:] $(1 / 3 times 600 / 400 + 1 / 3 times frac(4 , 000, 4 , 000) + 1 / 3 times frac(7 , 500, 7 , 000)) times 100 = 119.04$

- If you invest an equal amount (e.g., $700$) in each stock, meaning 70 shares of A, 14 shares of B, and 5 shares of C, the return is: $1 / 3 times (600 / 400 - 1) + 1 / 3 times (frac(4 , 000, 4 , 000) - 1) + 1 / 3 times (frac(7 , 500, 7 , 000) - 1) = 19.04 %$

- When using #strong[market-value weighting];, large-cap stocks are overweighted.

- When using #strong[equal weighting];, small-cap stocks are overweighted.

#horizontalrule

== Bond Market Indices
<bond-market-indices>
- Bond market indices track the performance of a portfolio of bonds, serving as benchmarks for bond investors.
  - Investors use bond indices to assess interest rate movements, credit risk, and overall bond market performance.
- Unlike stock indices, which rely on frequently traded prices, bond indices face challenges due to infrequent trading and pricing difficulties.

#horizontalrule

== Well-Known Bond Market Indices
<well-known-bond-market-indices>
- #strong[Bloomberg Barclays Bond Indices];:
  - Covers government, corporate, and municipal bonds across different maturities and risk levels. \
  - Examples: Bloomberg U.S. Aggregate Bond Index, Bloomberg Global Aggregate Index.
- #strong[ICE BofA (Merrill Lynch) Bond Indices];:
  - Tracks corporate and government bonds, commonly used for high-yield and investment-grade bonds. \
  - Example: ICE BofA U.S. High Yield Index.
- #strong[FTSE Russell Bond Indices (Citi)];:
  - Offers broad and sector-specific bond benchmarks. \
  - Example: FTSE World Government Bond Index (WGBI).
- #strong[S&P Dow Jones Fixed Income Indices];:
  - Includes indices such as the S&P U.S. Treasury Bond Index and S&P Muni Bond Index.

#horizontalrule

== Challenges in Bond Market Indices
<challenges-in-bond-market-indices>
- #strong[Infrequent Trading];:
  - Unlike stocks, bonds are often traded over-the-counter (OTC) and do not have centralized exchanges. \
  - Many bonds are bought and held by institutional investors, resulting in fewer transactions.
- #strong[Price Estimation Issues];:
  - Since many bonds do not trade daily, index providers estimate bond prices using models, dealer quotes, or matrix pricing. \
  - Matrix pricing estimates a bond’s value based on yields of similar bonds.
- #strong[Return Calculation Complexity];:
  - Unlike stocks, bond returns depend on interest payments, price changes, and reinvestment of coupon payments. \
  - Many bonds have embedded options (callable, putable), making valuation more complex.

#horizontalrule

== How Are Bond Market Indices Computed?
<how-are-bond-market-indices-computed>
=== Step 1: Selection of Bonds
<step-1-selection-of-bonds>
- The index provider selects a set of bonds based on criteria such as:
  - Issuer (government, corporate, municipal)
  - Credit rating (investment grade, high yield)
  - Maturity (short-term, medium-term, long-term)
  - Currency denomination (USD, EUR, JPY, etc.)

=== Step 2: Weighting Methodology
<step-2-weighting-methodology>
- #strong[Market Value-Weighted (Most Common)]
  - Bonds with larger outstanding amounts have greater influence on the index. \
  - Example: Bloomberg U.S. Aggregate Bond Index.
- #strong[Equal-Weighted]
  - All bonds have the same weight, regardless of their market size. \
  - Less common but used in some specialized indices.
- #strong[Duration-Weighted]
  - Adjusts weights based on a bond’s sensitivity to interest rate changes.

=== Step 3: Price and Yield Estimation
<step-3-price-and-yield-estimation>
- Since bonds do not always trade daily, prices are estimated using:
  - Last trade prices (if available).
  - Dealer quotes from financial institutions.
  - Matrix pricing (estimating prices based on similar bonds).

=== Step 4: Return Calculation
<step-4-return-calculation>
- #strong[Total Return Formula] (includes both price changes and interest income): \
  $ upright("Total Return") = frac(P_(upright("end")) - P_(upright("start")) + C, P_(upright("start"))) $ where:
  - $P_(upright("start"))$ = Bond price at the beginning of the period.
  - $P_(upright("end"))$ = Bond price at the end of the period.
  - $C$ = Coupon payment received.

#horizontalrule

== Example: Bloomberg U.S. Aggregate Bond Index
<example-bloomberg-u.s.-aggregate-bond-index>
- #strong[Composition:]
  - Includes U.S. government bonds, mortgage-backed securities, and corporate bonds.
  - Weighted by market capitalization.
- #strong[Performance Calculation Example:]
  - Suppose the index starts at #strong[100];.
  - A corporate bond in the index has:
    - Initial price: $98$
    - Final price: $100$
    - Coupon payment: $3$
  - #strong[Total Return Calculation:] $ (frac(100 - 98 + 3, 98)) times 100 = 5.10 % $
  - If the overall index return averages 5%, the index value would increase from #strong[100 to 105];.

= Derivatives Markets
<derivatives-markets>

#horizontalrule

== Derivatives Markets
<derivatives-markets-1>
- #strong[Financial contracts whose value is derived from an underlying asset];.
- Used for #strong[hedging, speculation, and arbitrage];.
- Traded in two main markets:
  - #strong[Exchange-traded derivatives (ETDs):] Standardized contracts traded on formal exchanges (e.g., CME, KRX).
  - #strong[Over-the-counter (OTC) derivatives:] Customized contracts traded directly between parties; OTC markets are much larger.

#horizontalrule

== Types of Derivatives
<types-of-derivatives>
+ #strong[Forwards & Futures];:
  - An agreement to buy/sell an underlying asset at a specified future date for a predetermined price.
  - #strong[Forwards];: Custom contracts traded OTC. \
  - #strong[Futures];: Standardized contracts traded on exchanges (e.g., S&P 500 futures, KOSPI 200 futures).
+ #strong[Options];:
  - #strong[Buyers have the right, but not the obligation,] to buy (call option) or sell (put option) an asset at a predetermined price before or at expiration.
  - #strong[European options];: Exercisable only at expiration.
  - #strong[American options];: Exercisable anytime before expiration.
  - #strong[Warrants];: Long-term options issued by a company.
+ #strong[Swaps];:
  - Contracts in which two parties #strong[exchange cash flows or financial instruments] over time.
  - Common types:
    - #strong[Interest rate swaps];: Exchange of fixed-rate and floating-rate payments.
    - #strong[Currency swaps];: Exchange of payments in different currencies.
    - #strong[Credit default swaps (CDS)];: A form of insurance against bond default.

#horizontalrule

=== Derivatives Market in Korea: Historical Development
<derivatives-market-in-korea-historical-development>
#table(
  columns: (12%, 88%),
  align: (auto,auto,),
  table.header([Year], [Event],),
  table.hline(),
  [#strong[May 1996];], [#strong[KOSPI 200 futures] introduced, marking the start of Korea’s exchange-traded derivatives market.],
  [#strong[July 1997];], [#strong[KOSPI 200 options] launched, quickly becoming one of the most actively traded derivatives globally.],
  [#strong[January 2001];], [#strong[KOSDAQ 50 futures] introduced (renamed #strong[KOSDAQ 150 futures] in 2015).],
  [#strong[November 2001];], [#strong[KOSDAQ 50 options] launched, providing additional hedging and speculation opportunities.],
  [#strong[January 2002];], [#strong[Single stock options] introduced, allowing investors to trade options on individual stocks.],
  [#strong[May 2008];], [#strong[Single stock futures] launched, enabling futures trading on specific company stocks.],
  [#strong[March 2018];], [#strong[Mini KOSPI 200 futures] introduced (1/5 the size of KOSPI 200 futures contracts).],
  [#strong[March 2018];], [#strong[KRX 200 futures] introduced as an expanded market index derivative.],
)

#horizontalrule

== Additional Insights: Global vs.~Korean Derivatives Market
<additional-insights-global-vs.-korean-derivatives-market>
- #strong[KOSPI 200 options] were at one point #strong[the world’s most actively traded derivative contract] due to heavy retail investor participation (2000s–Early 2010s).
- Korea’s derivatives market has evolved to #strong[reduce excessive speculation] by implementing #strong[trading restrictions and transaction taxes] (2014).
- #strong[Compared to global derivatives markets];:
  - #strong[U.S. & Europe];: Heavily institutional participation, with a focus on hedging.
  - #strong[Korea & China];: Historically, high retail investor involvement.
  - #strong[Emerging markets];: Increasing adoption of exchange-traded derivatives to develop capital markets.

#horizontalrule

== Example: How a Derivative Works
<example-how-a-derivative-works>
#strong[Hedging with KOSPI 200 Futures]

- An institutional investor holds a #strong[₩10 billion portfolio] tracking the #strong[KOSPI 200 index];.
- They fear a short-term market decline and #strong[short 100 KOSPI 200 futures contracts] to hedge their position.
- If the KOSPI 200 index drops by #strong[5%];, their stock portfolio loses #strong[₩500 million];, but their #strong[short futures position gains ₩500 million];, offsetting the loss.
- This strategy allows the investor to protect their portfolio #strong[without selling their stocks];.

#horizontalrule

== Derivatives Markets: Futures
<derivatives-markets-futures>
#block[
#box(image("img/market_Korea_Futures.png"))

]

#horizontalrule

== Derivatives Markets: KOSPI Futures vs.~KOSPI
<derivatives-markets-kospi-futures-vs.-kospi>
#block[
#box(image("img/market_KOSPI200futures_KOSPI.png"))

]

#horizontalrule

== Derivatives Markets: Other Countries
<derivatives-markets-other-countries>
#block[
#box(image("img/market_World_Futures_Market.png")) #box(image("img/market_World_Option_Market.png"))

]

#horizontalrule

== Derivatives Markets: Size
<derivatives-markets-size>
#block[
#box(image("img/market_Derivatives_Market.png"))

Source: Capital Market Factbook - SIFMA, 2024

]

#horizontalrule

== Derivatives Markets: Interest Rate Derivatives
<derivatives-markets-interest-rate-derivatives>
==== Interest Rate Futures
<interest-rate-futures>
- #strong[CD Futures];: Introduced in #strong[April 1999];, but #strong[delisted in December 2007] due to low trading volumes. \
- #strong[3-Year KTB Futures];: Launched in #strong[September 1999];, tracking Korean Treasury Bonds (KTBs). \
- #strong[MSB Futures];: Introduced in #strong[December 2002];, but #strong[delisted in February 2011];.

==== Interest Rate Swaps (IRS)
<interest-rate-swaps-irs>
- A #strong[contract between two parties] to exchange interest payment obligations, typically #strong[fixed-rate vs.~floating-rate payments];. \
- #strong[Maturity];: Ranges from #strong[3 months to 20 years];, with #strong[1- to 5-year swaps] being the most actively traded. \
- Developed as an #strong[OTC market in 1999];, with #strong[significant growth post-2005];, driven by increasing institutional demand.

#horizontalrule

== Derivatives Markets: Currency Derivatives
<derivatives-markets-currency-derivatives>
==== Currency Swaps
<currency-swaps>
- A #strong[contract where two parties exchange principal and interest payments] on loans denominated in different currencies. \
- Used for #strong[hedging currency risk] and #strong[lowering financing costs];. \
- #strong[Maturity];: Typically #strong[3 months to 20 years];, with #strong[1- to 5-year swaps] being the most liquid. \
- #strong[First currency swap in Korea];: Conducted #strong[OTC in September 1999];, marking the start of a growing swap market.

==== Forward Contracts on Currency
<forward-contracts-on-currency>
- #strong[Outright Forward];:
  - A commitment to exchange a specific amount of currency at a #strong[fixed rate on a future date];. \
  - Can be #strong[deliverable] (physical exchange of currency) or #strong[non-deliverable (NDF)] (cash-settled based on exchange rate differences).
- #strong[Forward Exchange Swap];:
  - A combination of a #strong[spot transaction] and a #strong[forward contract];, allowing investors to roll over foreign exchange exposure efficiently. \
  - Commonly used for #strong[corporate hedging and carry trade strategies];.

#horizontalrule

== Derivatives Markets: Currency Derivatives
<derivatives-markets-currency-derivatives-1>
#block[
#box(image("img/market_Forex_Derivatives.png"))

]

#horizontalrule

== Derivatives Markets: Credit Derivatives
<derivatives-markets-credit-derivatives>
=== Credit Derivatives
<credit-derivatives>
- #strong[Financial instruments that allow the separation and transfer of credit risk] from an underlying asset between a #strong[protection buyer] and a #strong[protection seller];. \
- Used for #strong[hedging credit exposure];, #strong[enhancing yields];, and #strong[speculating on credit risk];. \
- Requires #strong[precise definitions] of:
  - #strong[Credit events] (e.g., default, bankruptcy, credit downgrade).
  - #strong[Timing of credit risk transfer];.

#horizontalrule

== Types of Credit Derivatives
<types-of-credit-derivatives>
+ #strong[Credit Default Swap (CDS)]
  - A contract where the #strong[protection seller] compensates the #strong[protection buyer] if the reference entity experiences a credit event. \
  - Commonly used to hedge against #strong[default risk] on bonds and loans.
+ #strong[Total Return Swap (TRS)]
  - A swap where one party #strong[receives the total return] (price appreciation + interest/coupon payments) of an underlying credit asset, while the other #strong[receives a fixed or floating payment];. \
  - Transfers #strong[both credit risk and market risk] between counterparties.
+ #strong[Credit-Linked Notes (CLNs)]
  - A structured bond where the #strong[principal repayment is contingent on the credit performance] of a reference entity. \
  - Equivalent to a #strong[bond combined with a short CDS position];. \
  - Investors take on #strong[credit risk in exchange for higher yields];.
+ #strong[Synthetic Collateralized Debt Obligation (Synthetic CDO)]
  - A structured product that pools #strong[CDS contracts instead of actual bonds or loans];. \
  - Investors #strong[gain exposure to diversified credit risks] while earning returns based on the underlying CDS premiums. \
  - Used for #strong[leveraging credit exposure without direct asset ownership]

#horizontalrule

== Derivatives Markets: CDS and TRS
<derivatives-markets-cds-and-trs>
#block[
#box(image("img/market_CDS_structure.png")) #box(image("img/market_TRS_structure.png"))

]

#horizontalrule

== Derivatives Markets: CLN and CDO
<derivatives-markets-cln-and-cdo>
#block[
#box(image("img/market_CLN_structure.png")) #box(image("img/market_CDO_structure.png"))

]

#horizontalrule

== Derivatives Markets: CDS Premium
<derivatives-markets-cds-premium>
#block[
#box(image("img/market_CDS_Premium.png")) #box(image("img/market_CDS_Korea.png"))

]

#horizontalrule

== Derivatives Markets: Size
<derivatives-markets-size-1>
#block[
#box(image("img/market_Credit_Derivatives.png"))

]

#horizontalrule

== Derivatives Markets: Derivative-linked securities
<derivatives-markets-derivative-linked-securities>
- Financial products whose returns are tied to underlying assets, including #strong[stocks, interest rates, currencies, and commodities];.

=== #strong[\1. Equity-Linked Warrants (ELWs)]
<equity-linked-warrants-elws>
- #strong[Introduced in 2005] \
- Similar to stock options but #strong[without daily margin settlement];. \
- Allows investors to #strong[gain exposure with a small initial investment];. \
- Primarily used for #strong[short-term speculation and leverage];.

#block[
#box(image("img/market_ELW_vs_Options.png"))

]

#horizontalrule

== Derivatives Markets: Derivative-linked securities
<derivatives-markets-derivative-linked-securities-1>
=== #strong[\2. Equity-Linked Securities (ELS)]
<equity-linked-securities-els>
- #strong[Introduced in 2003] \
- Structured financial products linked to #strong[equities or indices];. \
- Offers a #strong[wide range of payoff structures];, such as:
  - #strong[Autocallable ELS];: Provides early redemption if conditions are met. \
  - #strong[Principal-Protected ELS];: Guarantees initial investment if held to maturity. \
  - #strong[Leveraged ELS];: Enhances returns with embedded derivatives.

#block[
#box(image("img/market_ELS.png"))

]

#horizontalrule

== Derivatives Markets: Common ELS Payoff Structure
<derivatives-markets-common-els-payoff-structure>
#block[
#box(image("img/market_ELS_example.png"))

]

#horizontalrule

== Derivatives Markets: Derivative-linked securities
<derivatives-markets-derivative-linked-securities-2>
=== #strong[\3. Debt-Linked Securities (DLS)]
<debt-linked-securities-dls>
- #strong[Introduced in 2005] \
- Tied to #strong[interest rates, foreign exchange rates, commodity prices, and credit events];. \
- Primarily used by #strong[institutional investors] for #strong[risk management and yield enhancement];.

#block[
#box(image("img/market_CLN.png"))

]

#horizontalrule

== Derivatives Markets: Derivative-linked securities
<derivatives-markets-derivative-linked-securities-3>
=== #strong[\4. Exchange-Traded Notes (ETNs)]
<exchange-traded-notes-etns>
- #strong[Introduced in 2014] \
- #strong[Hybrid between derivatives and fixed-income products];:
  - #strong[ELWs] behave like #strong[options];. \
  - #strong[ELS/DLS] behave like #strong[fixed-income securities];. \
  - #strong[ETNs] behave like #strong[ETFs] but without actual asset ownership.

#block[
#box(image("img/market_ETN_vs_ETF.png"))

]

#horizontalrule

== Derivatives Markets: Comparison of Derivative-Linked Products
<derivatives-markets-comparison-of-derivative-linked-products>
#table(
  columns: (17.54%, 38.6%, 21.05%, 22.81%),
  align: (auto,auto,auto,auto,),
  table.header([#strong[Type];], [#strong[Underlying Assets];], [#strong[Issuer];], [#strong[Features];],),
  table.hline(),
  [#strong[ELS];], [Individual stocks, indices], [Securities firms], [Structured equity exposure],
  [#strong[DLS];], [Interest rates, FX, commodities], [Securities firms], [Linked to non-equity assets],
  [#strong[ELT];], [Stocks, indices], [Banks], [Similar to ELS but bank-issued],
  [#strong[DLT];], [Interest rates, FX, commodities], [Banks], [Similar to DLS but bank-issued],
  [#strong[ELF];], [Stocks, indices], [Asset management firms], [Fund-based structured products],
  [#strong[DLF];], [Interest rates, FX, commodities], [Asset management firms], [Fund-based debt-linked investments],
  [#strong[ELD];], [Stocks, indices], [Banks], [#strong[Principal-protected] deposits],
  [#strong[DLD];], [Interest rates, FX, commodities], [Banks], [#strong[Principal-protected] deposits],
  [#strong[Options];], [Any tradable asset], [Anyone], [Direct derivative contracts],
  [#strong[Warrants];], [Individual stocks], [Issued by companies], [Stock purchase rights],
  [#strong[ELW];], [Individual stocks, indices], [Securities firms], [Similar to options but no margin calls],
  [#strong[ETN];], [Various asset classes], [Securities firms], [#strong[Trade like ETFs but unsecured debt];],
  [#strong[ETF];], [Various asset classes], [Asset management firms], [#strong[Fund with underlying asset ownership];],
)

#horizontalrule

== Derivatives Markets: Comparison of Derivative-Linked Products
<derivatives-markets-comparison-of-derivative-linked-products-1>
- E: individual stocks or indices

- D: forex, gold, credit, etc.

- ELS and DLS: issued by securities companies

- ELT and DLT: issued by banks

- ELF and DLF: issued by asset managment companies

- ELD and DLD: principal protected

- Options (anyone), Warrants (Companies), ELW (securities companies)

- ETN (securities companies), ETF (funds)

#horizontalrule

== Risk/Return Characteristics of Securities
<riskreturn-characteristics-of-securities>
=== #strong[Understanding Risk and Return]
<understanding-risk-and-return>
- Financial securities exhibit #strong[different risk-return profiles];, which are central to #strong[asset allocation decisions];. \
- #strong[Risk and return trade-off];: Investors demand #strong[higher returns for higher risks] over the long run.

#horizontalrule

== Risk/Return Characteristics of Securities
<riskreturn-characteristics-of-securities-1>
=== #strong[Factors Affecting the Risk of a Security]
<factors-affecting-the-risk-of-a-security>
+ #strong[Maturity of the Security]
  - Longer-term securities generally carry #strong[higher risk] due to #strong[interest rate fluctuations and uncertainty];. \
  - Example: #strong[30-year bonds] are riskier than #strong[1-year Treasury bills];.
+ #strong[Credit Quality of the Issuer]
  - Issuers with lower credit ratings offer #strong[higher yields] but come with #strong[default risk];. \
  - Example: #strong[U.S. Treasury bonds (AAA-rated, low risk)] vs.~#strong[junk bonds (BB-rated or lower, high risk)];.
+ #strong[Priority Over Income and Assets]
  - #strong[Senior debt] is repaid first in bankruptcy, making it safer than #strong[subordinated debt] or #strong[equity];. \
  - Example: #strong[Common stock] is riskier than #strong[corporate bonds] because bondholders are paid first.
+ #strong[Liquidity]
  - More liquid assets can be easily bought or sold without affecting their price. \
  - Example: #strong[Large-cap stocks (Apple, Microsoft) are highly liquid];, while #strong[small-cap stocks or private debt] may have limited liquidity.

#horizontalrule

== Risk/Return Characteristics of Securities
<riskreturn-characteristics-of-securities-2>
=== #strong[Risk and Return Relationship]
<risk-and-return-relationship>
- #strong[Higher risk should be compensated with higher expected returns] over the long term. \
- #strong[Typical return hierarchy (from lowest to highest risk/return):]
  + #strong[Government Bonds] (low risk, low return) \
  + #strong[Investment-Grade Corporate Bonds] \
  + #strong[High-Yield Bonds (Junk Bonds)] \
  + #strong[Large-Cap Stocks] \
  + #strong[Small-Cap Stocks] \
  + #strong[Private Equity / Venture Capital] (high risk, high return)

#horizontalrule

== Risk vs.~Return
<risk-vs.-return>
#block[
#box(image("img/market_RiskReturn.png"))

Source: #link("")[BNP Paribas]

]




