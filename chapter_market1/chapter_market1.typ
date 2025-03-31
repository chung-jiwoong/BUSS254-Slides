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
  title: [Financial Markets: Part I],
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
- #text(fill: red)[Money markets: Call, Repo, CD, CP, etc.]
- Capital markets: Bond, Equity
- Derivatives markets: Futures, options etc.
- Trading mechanisms
- Investment Companies
- Reading: BKM Ch. 1 and 2, "Financial Markets in Korea" Bank of Korea (2022)

= Money Markets
<money-markets>

#horizontalrule

== Financial Instruments
<financial-instruments>
#block[
#box(image("img/market_Financial_Market.png"))

]

#horizontalrule

== Financial Market Size in Korea
<financial-market-size-in-korea>
#block[
#box(image("img/market_Financial_Market_Size.png"))

]

#horizontalrule

== Financial Market Size: Global
<financial-market-size-global>
#block[
#box(image("img/market_Global_Market_Size.png"))

]

#horizontalrule

== What Are Money Markets?
<what-are-money-markets>
- Provide #strong[short-term liquidity] to financial institutions, corporations, and investors.

- Instruments have #strong[maturities ranging from one day to one year];.

- A #strong[vital part of the financial system];, ensuring short-term funding.

- Heavily regulated by governments and central banks due to its importance.

- Regulations of money markets vary widely over time and across jurisdictions.

  - Individuals typically access the instruments via a mutual fund (money market mutual fund).

- Typical characteristics

  - == Short maturity (overnight \~ 1 year), high liquidity, Low risk, Low return, Large denomination: typically large institutions, Dealer market
    <short-maturity-overnight-1-year-high-liquidity-low-risk-low-return-large-denomination-typically-large-institutions-dealer-market>

== Money Markets: Size
<money-markets-size>
#block[
#box(image("img/market_Money_Market_Size.png", width: 100%))

]
- Developed in the 1960s–1970s, expanded in the 1990s due to interest rate liberalization and financial sector reforms (the Asian crisis).

- Since the late 2000s, restructuring efforts aimed at improving efficiency

- Korea’s money markets have shifted towards repos, CPs, and short-term bonds, reflecting regulatory changes and financial innovation (discuss later).

#horizontalrule

== Money Markets: Global
<money-markets-global>
#block[
#box(image("img/market_Global_Money_Market.png", width: 100%))

]
== Call Market
<call-market>
- A marketplace where financial institutions borrow (lend) money on a very short-term basis to resolve their temporary surpluses or shortages of funds (interbank loans).#footnote[In Korea, there are 3 brokers: the Korea Money Brokerage Corporation, Seoul Money Brokerage Services, and the KIDB Money Brokerage Corporation.]

  - Mostly, uncollateralized, brokered, and overnight.

- For banks that must hold reserve requirements, the call market helps them to smooth shortages or excesses in their reserve balances.

- The call market is also important in the implementation of monetary policy.

  - Before 2008, BOK directly set call rate as the Base Rate
  - Now, call rates are closely linked to BOK repo rate (via open market operations).

- Known as the Federal funds market in the U.S., the Call market in Japan, and the Unsecured market in Europe.

#horizontalrule

== Call Market: Open Market Operations
<call-market-open-market-operations>
- The BOK targets the call rate (Base Rate) in its monetary policy, announcing it after regular policy meetings.
- By buying government securities, the BOK increases bank reserves and the money supply, lowering the call rate. Selling securities has the opposite effect. These actions are known as open market operations.

#block[
#box(image("img/market_Call_Rate.png"))

]

#horizontalrule

== Call Market: Regulations
<call-market-regulations>
- The Korean government restricted securities firms’ borrowing in 2010 and excluded non-banks from the call market in 2015 to enhance financial stability and reduce systemic risk.

  - Reducing Short-Term Funding Risks – Heavy reliance on call markets made financial institutions vulnerable to liquidity shocks.

  - Preventing Excessive Leverage & Arbitrage – Some non-banks used call market funds for high-risk investments, increasing systemic risk.

  - Strengthening Monetary Policy Transmission – Non-bank participation distorted Bank of Korea’s interest rate policies.

  - Promoting the Repo Market – The government encouraged secured repo transactions, reducing counterparty risk and making repos the dominant funding source.

#horizontalrule

== Call Market: Evolution
<call-market-evolution>
#block[
#box(image("img/market_Call_Market.png"))

]
- Impact:

  - Call market share dropped from 10.1% (2010) to 1.3% (2016).
  - Repo market expanded, replacing the call market as the primary short-term funding mechanism.
  - These measures aligned with global post-2008 financial reforms, ensuring a more resilient financial system

#horizontalrule

== Repurchase Agreement (RP)
<repurchase-agreement-rp>
A #strong[repurchase agreement (repo)] is a short-term secured loan where securities serve as collateral.

- #strong[Mechanism];:
  - One party sells securities (ownership transfer) and agrees to repurchase them later at a higher price.
  - Securities serve as #strong[high-credit-quality collateral];.
  - From the #strong[buyer’s perspective];, this is called a #strong[reverse repo];.
  - The #strong[repo rate] is the implied interest rate based on the price difference.

#horizontalrule

== RP: Types of Repos
<rp-types-of-repos>
#strong[By Participants]

- #strong[Customer repos];: Between financial institutions and their clients. \
- #strong[Institutional repos];: Among financial institutions. \
- #strong[Bank of Korea (BOK) repos];: Between the BOK and institutions.

#strong[By Maturity]

- #strong[Overnight repo];: Expires the next day. \
- #strong[Term repo];: Fixed maturity beyond overnight. \
- #strong[Open repo];: No fixed maturity; can be rolled over.

#strong[By Collateral Management]

- #strong[Delivery repo];: Collateral is transferred to the buyer. \
- #strong[Tri-party repo];: A third party (custodian) holds collateral. \
- #strong[Hold-in-custody repo];: Seller retains collateral (common in customer repos).

#horizontalrule

== RP: Market Size
<rp-market-size>
#block[
#box(image("img/market_Repo_Market.png"))

- As of 2020, €8.3 trillion in Euro, \$2.7 trillion in U.S.
- Alternative to deposits or MMFs.
- Tighter regulation on the call market drove non-bank financial institutions to the repo market.

]

#horizontalrule

== #strong[Role of the Repo Market]
<role-of-the-repo-market>
- Enables financial institutions (e.g., banks, broker-dealers, hedge funds\*) to borrow #strong[cheaply] using securities as collateral. \
- Provides cash-rich entities (e.g., money market mutual funds, corporations) with a #strong[low-risk] return. \
- Supports #strong[market liquidity] and #strong[efficient collateralized borrowing];.

#strong[Repos and Monetary Policy]

- #strong[Central banks] use #strong[repos and reverse repos] to manage liquidity and control short-term rates.
  - #strong[Injecting liquidity];: A reverse transaction (#strong[central bank buys securities];) adds reserves to the system. \
  - #strong[Draining liquidity];: A repo (#strong[central bank sells securities];) absorbs reserves, reducing money supply. \
  - #strong[Repo rates influence] credit conditions, inflation, and economic growth.

#strong[Significance of the Repo Market]

- Ensures #strong[efficient money markets] and short-term funding. \
- Facilitates #strong[monetary policy transmission] and #strong[interest rate stability];. \
- Plays a key role in #strong[financial system stability] through collateralized lending.

#horizontalrule

== BOK Repo
<bok-repo>
- BOK holds regular auctions of seven-day maturity repo sales every Thursday in order to control short-term liquidity.

  - Flexibly controls timing and collateral securities

#block[
#box(image("img/market_BOK_repo.png"))

]
- Repo: liquidity absorption
- Reverse repo: liquidition provision

#horizontalrule

== Certificate of Deposites (CD)
<certificate-of-deposites-cd>
- A #strong[Certificate of Deposit (CD)] is a #strong[time deposit] issued by banks with a #strong[fixed maturity and interest rate];. \
- #strong[Negotiable CDs] can be #strong[transferred or traded] in the secondary market, unlike non-negotiable CDs.

#strong[Key Features of CDs]

- #strong[Subject to reserve requirements];, similar to regular deposits. \
- #strong[Not covered by deposit insurance] since 2001 (unlike U.S. CDs). \
- #strong[Issued at a discount] (investors receive face value at maturity).

#strong[CD Rate Determination in Korea]

- The #strong[CD rate] is published #strong[twice daily] (12:00 and 16:30) by the #strong[Korea Financial Investment Association];. \
- Based on #strong[91-day CDs issued by AAA-rated nationwide banks];. \
- Calculated as a #strong[simple average] of rates from #strong[10 securities companies];, excluding the highest and lowest quotes, rounded to the third decimal place.

#horizontalrule

== #strong[CD Rate and Its Role]
<cd-rate-and-its-role>
- The #strong[CD rate] serves as a key #strong[reference rate] for:
  - #strong[Floating-rate loans] and #strong[interest rate swaps];.
  - Influencing #strong[bank loan] and #strong[deposit rates];. \
- However, #strong[91-day CDs] lack liquidity and may be #strong[unrepresentative];, leading to potential volatility.

#strong[Alternative Short-Term Reference Rates]

To address CD rate limitations, several alternative benchmarks have been introduced: \
\- #strong[KORIBOR] (Korea Inter-Bank Offered Rate) – Established in #strong[July 2004];. \
\- #strong[COFIX] (Cost of Funds Index) – Introduced in #strong[February 2010];. \
\- #strong[KOFR] (Korea Overnight Financing Reference Rate) – Launched in #strong[February 2021];, based on #strong[repo rates] for government bonds and #strong[Monetary Stabilization Bonds (MSB)];.

#horizontalrule

== Certificate of Deposits: Rates
<certificate-of-deposits-rates>
#block[
#box(image("img/market_CD_Rate.png"))

]
- CD rates are sometimes "sticky."

#horizontalrule

== Commercial Paper (CP)
<commercial-paper-cp>
- A short-term #strong[unsecured] debt instrument issued by corporations with strong #strong[credit ratings] to raise funds (e.g., for working capital). \
- #strong[Key Features];:
  - #strong[Faster and easier] to issue than bonds or stocks. \
  - #strong[Not backed by collateral];, except for #strong[asset-backed CPs (ABCPs)];. \
  - #strong[Lower interest rates] compared to bank loans. \
  - Must be #strong[rated by at least two rating agencies];. \
  - #strong[Issued at a discount] (investors receive face value at maturity).

#strong[CP Rate Determination in Korea]

- The #strong[CP rate] is published #strong[twice daily] (12:00 and 16:30) by the #strong[Korea Financial Investment Association];. \
- Based on #strong[A1-rated CPs (highest grade)] from eight financial institutions. \
- Computed as a #strong[simple average] of the six middle values after removing the highest and lowest rates.

#horizontalrule

== Asset-Backed Commercial Paper (ABCP)
<asset-backed-commercial-paper-abcp>
- #strong[Backed by underlying assets] such as:
  - Term deposits, loans, corporate bonds, trade receivables, real estate, etc. \
- Typically issued through a #strong[Special Purpose Company (SPC)] via #strong[securitization];.

#block[
#box(image("img/market_ABCP.png"))

]
- Credit Enhancement Providers reduce default risk by, e.g., providing guarantees.
- Liquidity Providers cover maturing ABCPs, e.g., if investors don’t roll over.
- Placement agents are intermediaries promoting ABCPs, helping determine competitive pricing.

#horizontalrule

== Commercial Paper: Evolution
<commercial-paper-evolution>
#block[
#box(image("img/market_CP_Market.png"))

]
- Rapid CP market expansion since the mid-2000s due to the convenience of ABCP issuance.
- Surge in PF ABCP issuance driven by:
  - Booming construction market.
  - Regulatory changes shifting real estate PF ABS to PF ABCP.

#horizontalrule

== Commercial Paper: Rates
<commercial-paper-rates>
#block[
#box(image("img/market_CP_Rate.png"))

]
- The CP market in Korea occasionally experiences periods of stress.

#strong[Recent Developments: Gangwon-do Default]

- #strong[Background];: Gangwon-do province’s real-estate developer (GJC) issued an ABCP for the Legoland project, guaranteed by the province.
- #strong[Default Event];: GJC missed a principal payment; the province filed for rehabilitation instead of honoring the guarantee.
- #strong[Immediate Impact];: Credit rating agencies downgraded the ABCP from A1 to D within five days.
- #strong[Government Response];: Special Purpose Vehicle (SPV) created to purchase up to ₩1.8 trillion (\$1.33 billion) of PF-ABCP. Purchases to continue until May 30, 2023.

Source: #link("https://think.ing.com/articles/south-korea-corporate-debt-is-a-concern-for-the-economy/")[ING Think] / #link("https://www.reuters.com/article/markets/south-korea-s-pf-abcp-purchasing-program-to-start-from-thurs-idUSL1N32J0K6/")[Reuters]

#horizontalrule

== Short-Term Bonds
<short-term-bonds>
- Corporate bonds issued and distributed electronically

  - Though legally a bond, it works like CPs.
  - Unlike CPs, physical certificates are not issued.
  - CPs are electronically issued and traded in U.S. (since 2000)

- Introduced in January 2013 in Korea

  - To replace CP: improve transparency, require board’s approval
  - To diversify short-term funding for non-bank institutions away from CP and Call markets.

#horizontalrule

== Short-Term Bonds: Evolution
<short-term-bonds-evolution>
#block[
#box(image("img/market_STB_Market.png"))

]

#horizontalrule

== U.S. Treasury Bills
<u.s.-treasury-bills>
- Debt issued by the US Treasury with maturities under one year.

  - Maturities: 4, 8, 13, 26, or 52 weeks.
  - Issued at a discount, highly liquid, denominations of $gt.eq \$ 100$, exempt from state and local taxes, but subject to federal tax.
  - The most marketable money market instrument.

- The Federal Reserve is a major purchaser of these securities.

  - Federal Reserve’s monetary policy, through the federal funds rate, significantly impacts T-Bill prices.
  - Higher federal funds rates tend to reduce demand for Treasuries, and vice versa.

#horizontalrule

== U.S. Treasury: Foreign Holders
<u.s.-treasury-foreign-holders>
#block[
#box(image("img/market_UST_holders.png"))

]
- As of December 2024, Souce: U.S. Treasury

#horizontalrule

== U.S. Treasury Bills: Roles
<u.s.-treasury-bills-roles>
- Largest & Most Essential Bond Market: Due to U.S. creditworthiness and economic dominance, Treasuries (billes, notes, and bonds) form the deepest and most liquid bond market globally.
- Low-Cost Borrowing: The U.S. government benefits from relatively low financing costs over time.
- Safe-Haven Asset: Treasuries are seen as risk-free, near-cash assets, easily liquidated during market stress.
- Benchmark for Fixed-Income Markets: Treasury yields influence borrowing costs for consumers, businesses, and governments worldwide.
- Foundation of Global Finance: Treasury markets are critical to financial stability, serving as the bedrock of the global financial system.

#horizontalrule

== Eurodollars
<eurodollars>
- US Dollar-denominated deposits held at foreign banks or at foreign branches of American banks (outside the U.S.).

  - These deposits are not regulated by the Federal Reserve, often resulting in higher interest rates compared to domestic rates.
  - Most Eurodollar deposits are for large sums and typically have maturities of less than six months.

- The interest rate on overnight Eurodollars tends to closely track the federal funds rate.

  - For a U.S. bank with a reserve deficiency, borrowing Eurodollars is an alternative to purchasing federal funds.
  - Conversely, for a U.S. bank with excess funds, placing dollars in the Euromarket (Europlacement) is an alternative to selling federal funds.

- Similar instruments exist for other currencies, such as Euroyen, Eurosterling, and Eurofranc.

#horizontalrule

== Eurodollars: Roles
<eurodollars-roles>
- Global Liquidity and Funding Source
  - Provides U.S. dollar-denominated funding to banks, corporations, and governments outside the U.S.
  - Facilitates global trade and investment, as the U.S. dollar is the world’s primary reserve currency.
- Supports the Offshore Dollar System
  - Enables non-U.S. banks and financial institutions to operate in dollars, strengthening dollar-based global finance.
  - Reduces reliance on U.S. domestic banks for dollar liquidity.
- Critical for Corporate and Sovereign Borrowing
  - Many multinational corporations and governments issue Eurodollar bonds to raise capital efficiently.
  - Provides an alternative to domestic debt markets with favorable interest rates.

#horizontalrule

== Money Market Mutual Funds (MMMF)
<money-market-mutual-funds-mmmf>
- #strong[Investment funds] that invest in #strong[short-term, highly liquid, low-risk securities];. \
- Designed to offer #strong[stability, liquidity, and competitive yields] compared to savings accounts.

#strong[Key Features]

- #strong[Stable Net Asset Value (NAV)];: Many funds maintain a #strong[\$1 per share NAV];. \
- #strong[Liquidity];: Investors can #strong[redeem funds quickly];, making them a cash-like investment. \
- #strong[Regulation];: Tightly regulated, which limits risk exposure. \
- #strong[Yields & Returns];: Typically offer #strong[higher returns than savings accounts] but lower than riskier investments.

#block[
#box(image("img/market_MMF_Korea.png"))

Source: #link("http://freesis.kofia.or.kr:8087/stat/FreeSIS.do?parentDivId=MSIS40100000000000&serviceId=STATFND0100200150")[KFIA]

]
#block[
#box(image("img/market_MMF_Global.png"))

Source: #link("https://www.bis.org/publ/qtrpdf/r_qt2312d.htm")[BIS]

]

#horizontalrule

== MMMF: Risks
<mmmf-risks>
#strong[Potential Risks]

- #strong[Interest Rate Risk];: MMMFs may experience #strong[declining yields] when interest rates drop. \
- #strong[Liquidity Risk];: Heavy redemptions can #strong[strain fund liquidity];. \
- #strong[Credit Risk];: Default risk exists, especially for #strong[prime MMMFs investing in CP];. \
- #strong[Regulatory Changes];: Stricter rules may #strong[impact fund structure and returns];.

#block[
#box(image("img/market_FED_MMF.png"))

Source: #link("https://www.kansascityfed.org/research/charting-the-economy-archive/the-feds-footprint-in-us-money-market-funds-has-grown-significantly-since-2021/")[FRB]

]
= Pricing Money Market Securities
<pricing-money-market-securities>

#horizontalrule

== Alternative Ways of Quoting Prices
<alternative-ways-of-quoting-prices>
- (Bond Equivalent) Yield (y) vs.~Discount (d)

- Depending on the jurisdiction/instruments, prices are quoted as y or d.

  - CDs and CPs issued at a discount, but quoted in yield in Korea
  - T-bills and CPs (but not CDs) are issued at a discount and quoted as discount in the U.S.

- Example: Pay \$90 for a \$100 zero that matures in 90 days.

  $ y = (frac(100 - 90, 90)) (365 / 90) = 0.4506 $

  $ d = (frac(100 - 90, 100)) (365 / 90) = 0.4055 $

#horizontalrule

== Alternative Ways of Quoting Prices (cont’d)
<alternative-ways-of-quoting-prices-contd>
Consider a zero coupon bond with price $P$ and face value $M$

#horizontalrule

== Example
<example>
- What is the 180-day discount \`\`factor’’ of 7% per year?

  $ 1 / (1 + 0.07 times 180 / 365) = 0.9666 $

- What is the price of a \$500 180-day zero coupon bond if the yield is 7%?

  $ 0.9666 times \$ 500 = \$ 483.31 $

- What is the discount on the face value of the bond?

  $ (1 - d times 180 / 365) = 0.9666 $

  $ d = 6.7728 % upright(", which is the same as ") (frac(500 - 483.31, 500)) (365 / 180) $

#horizontalrule

== Day Count Conventions
<day-count-conventions>
- Pricing in financial markets started long before computers…

  - People in different countries took different strategies to ease the calculation of accrued interests over time
  - 30 days per month? 360 or 365 days per year?

- Conventions vary from country to country and from instrument to instrument

  - $X \/ Y$, where $X$ is the number of days in a month, and $Y$ is the number of days in a year.

  - Actual/Acutal: US treasury bonds, Australia

  - 30/360 method: US corporate/municipal bonds, Eurobonds

  - Actual/360: US money market

  - Actual/365: Korea, UK, Japan

\[Source: #link("https://www.rbcits.com/en/gmi/global-custody/market-profiles.page")

#horizontalrule

== Example
<example-1>
- Consider a Treasury bond and a corporate bond both have the same annual coupon payment dates (Principal: \$100, coupon rate: 8%).

  - Their last coupon payment date is March 1, 2018, and the next coupon date is September 1, 2018.

- How much interest is accured for the period from March 1, 2018 to July 3, 2018, for the two bonds, respectively?

  - Act/Act: $124 / 184 times \$ 4 = 2.6957$
  - 30/360: $122 / 180 times \$ 4 = 2.7111$

- How about from October 3, 2018 to January 1, 2019?

  - Act/Act: $90 / 184 times \$ 4 = 1.9889$
  - 30/360: $88 / 180 times \$ 4 = 1.9555$

- Excel functions: `Days` and `Days360`

#horizontalrule

== Example (cont’d)
<example-contd>
- What if we use Actual/365?

  - Divide 8% by 365 = 0.02191
  - Multiply by \# of days from March 1 to July 3, 2018 (124) = 2.7178

- Actual/360?

  - Divide 8% by 360 = 0.02222
  - Multiply by \# of days from March 1 to July 3, 2018 (124) = 2.7555

- \[NB\] Therefore, 8% in Actual/360 is equivalent to $8 % times 365 / 360 = 8.1111 %$

  - Divide 8.1111% by 365 = 0.02222
  - Multiply by \# of days from March 1 to July 3, 2018 (124) = 2.7555

- \[NB\] 1% in Actual/360 would earn $1 % times 365 \/ 360$ of interest in 365 days.

#horizontalrule

== Pricing CDs
<pricing-cds>
- A 90-day CD with \$100,000 face value was issued on March 17, 2015 in the U.S., offering a 6% yield (under ACT/360 day convention) with a market rate of 7 %.
- \[NB\] Unlike US, CDs are issued at a discount in Korea.

+ Compute the payoff.
+ Compute the price of the CD on March 17, 2015
+ On April 10, 2015, the market rate dropped to 5.5 percent. Compute the price of the CD in the secondary market
+ On May 10, the market rate further dropped to 5 percent. Compute the return of an investor that purchased the CD on April 10 and sold it on May 10 (30 days)

#horizontalrule

== Pricing CDs (cont’d)
<pricing-cds-contd>
+ Compute the payoff.

  - Payoff $= 100 , 000 times (1 + 6 % times 90 / 360) = 101 , 500$

+ Compute the price of the CD on March 17, 2015

  - $P V = frac(101 , 500, (1 + 7 % times 90 / 360)) = 99 , 754$

+ On April 10, 2015, the market rate dropped to 5.5 percent. Compute the price of the CD in the secondary market

  - `Days(Date(2015,4,10),Date(2015,3,17))=24`
  - $P V = frac(101 , 500, (1 + 5.5 % times frac(90 - 24, 360))) = 100 , 487$

#horizontalrule

== Pricing CDs (cont’d)
<pricing-cds-contd-1>
#block[
#set enum(numbering: "1.", start: 4)
+ On May 10, the market rate further dropped to 5 percent. Compute the return of an investor that purchased the CD on April 10 and sold it on May 10 (30 days)

  - `Days(Date(2015,5,10),Date(2015,3,17))=54`
  - $P V = frac(101 , 500, (1 + 5.0 % times frac(90 - 54, 360))) = 100 , 995$
  - `Days(Date(2015,5,10),Date(2015,4,10))=30`
  - $R e t u r n = (frac(100 , 995, 100 , 487) - 1) times 360 / 30 = 6.07 %$
]

#horizontalrule

== Commerical Paper Yields
<commerical-paper-yields>
- Yields on commercial paper are quoted on a discount basis (like Treasurey bills) in the U.S.

- A 60-day CP has a nominal (face) value of \$100,000. It is issued at a discount of $7.5 %$ per annum (Act/360). The discount is calculated as:

  $ d = 0.075 times 60 / 360 times \$ 100 , 000 = \$ 1 , 250 $

- The issue price for the CP is therefore \$\$100,000 - \$1,250 = \$98,750\$.

- The yield is:

  $ y = d / (1 - d times frac(d a y s, 360)) = 0.075 / (1 - 0.075 times 60 / 360) = 7.59 % $

  $ upright("or ") y = frac(\$ 1 , 250, \$ 98 , 750) times 360 / 90 = 7.59 % $

#horizontalrule

== U.S. Treasury Bill Quotes
<u.s.-treasury-bill-quotes>
- US T-bills are quoted on a discount basis (reference price is face value) using Act/360 method.

#block[
#box(image("img/market_T_bill.png", width: 120%))

]
- `Days360(Date(2022,12,15),date(2022,12,20))` = 5 days

$ P = (1 - d times 5 / 360) times 100 = (1 - 3.685 % times 5 / 360) times 100 = 99.9488 $

\$\$
y = ( \\frac{100-99.9488}{99.9488} \\times \\frac{\\color{red}{365}}{5} ) = 3.738\\% \\text{, which is ASKED YIELD}
\$\$

== Pricing Repo
<pricing-repo>
- X sells \$9,876,000 worth of T-bills and agrees to repurchase them in 14 days at \$9,895,000 in the U.S. What is the repo rate?

  $ y = (frac(9 , 895 , 000, 9 , 876 , 000) - 1) times 360 / 14 = 4.9470 % $

- If the overnight repo rate is 4.5% what is the payment tomorrow for a repo of \$10,000,000

  $ 10 , 000 , 000 times (1 + 0.045 times 1 / 360) = 10 , 001 , 250 $
