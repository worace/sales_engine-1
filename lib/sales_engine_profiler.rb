require_relative "sales_engine"
require "ruby_prof"
require "pry"

class SalesEngineProfiler
  TIMEOUT_THRESHOLD = 15 #seconds
  attr_reader :data_dir, :engine
  def initialize(data_dir)
    @data_dir = data_dir
  end

  def profiled(&block)
    RubyProf.start

    begin
      yield block
    rescue
      puts "OOPS WE BLEW UP"
    end

    result = RubyProf.stop
    output_path = File.join(__dir__, "..", "tmp")
    puts " got result #{result}"
    RubyProf::MultiPrinter.new(result).print(:path => output_path, :profile => "profile")
    File.open(File.join(output_path, "profile.dot"), "w") { |f| RubyProf::DotPrinter.new(result) }
  end

  def run
    profiled do
      puts "******* Benchmarking Sales Engine :) **********"
      @engine = SalesEngine.new(data_dir)
      puts "Starting Up..."
      engine.startup

      #customers
      5.times { customer_methods }
      #invoice_items
      5.times { invoice_item_methods }
      #invoices
      5.times { invoice_methods }
      #items
      5.times { item_methods }
      #merchants
      5.times { merchant_methods }
      #transactions
      5.times { transaction_methods }
      #BI
      business_intel
    end
  end

  def merchant_methods
    puts "Benchmarking Merchant Methods"
    engine.merchant_repository.random
    engine.merchant_repository.find_by_name "Marvin Group"
    engine.merchant_repository.find_all_by_name "Williamson Group"
    merchant = engine.merchant_repository.find_by_name "Kirlin, Jakubowski and Smitham"
    merchant.items
    merchant.invoices
  end

  def customer_methods
    puts "Benchmarking Customer Methods"
    engine.customer_repository.random
    engine.customer_repository.find_by_last_name "Ullrich"
    engine.customer_repository.find_all_by_first_name "Sasha"
    customer = engine.customer_repository.find_by_id 999
    customer.invoices
  end

  def invoice_item_methods
    puts "Benchmarking Invoice Item Methods"
    engine.invoice_item_repository.random
    engine.invoice_item_repository.find_by_item_id 123
    engine.invoice_item_repository.find_all_by_quantity 10
    invoice_item = engine.invoice_item_repository.find_by_id 16934
    invoice_item.item.name
  end

  def invoice_methods
    puts "Benchmarking Invoice Methods"
    engine.invoice_repository.random
    engine.invoice_repository.find_by_status "cool"
    engine.invoice_repository.find_all_by_status "shipped"
    engine.invoice_repository.find_by_id 1002

    invoice = engine.invoice_repository.find_by_id 1002
    invoice.transactions
    invoice.items
    invoice.customer
    invoice.invoice_items
    invoice.invoice_items.map { |ii| ii.item.name }

    creates_invoice
  end

  def item_methods
    puts "Benchmarking Item Methods"
    engine.item_repository.random
    engine.item_repository.find_by_unit_price BigDecimal.new("935.19")
    engine.item_repository.find_all_by_name "Item Eos Et"
    item = engine.item_repository.find_by_name "Item Saepe Ipsum"
    item.invoice_items
    item.merchant
  end

  def creates_invoice
    customer = engine.customer_repository.find_by_id(7)
    merchant = engine.merchant_repository.find_by_id(22)
    items = (1..3).map { engine.item_repository.random }

    engine.invoice_repository.create(customer: customer, merchant: merchant, items: items)
  end

  def transaction_methods
    puts "Benchmarking Transaction Methods"
    engine.transaction_repository.random
    engine.transaction_repository.find_by_credit_card_number "4634664005836219"
    engine.transaction_repository.find_all_by_result "success"
    engine.transaction_repository.find_by_id(1138).invoice.customer.first_name
  end

  def business_intel
    puts "Benchmarking Business Intelligence Methods"
    #customers
    puts "(customers business intel)"
    engine.customer_repository.find_by_id(2).transactions
    engine.customer_repository.find_by_id(2).favorite_merchant

    #merchants
    puts "(merchants business intel)"

    puts "revenue..."
    #doesnt finish
    time_capped("merchant revenue") { engine.merchant_repository.revenue(Date.parse "Tue, 20 Mar 2012") }
    puts "most revenue..."
    time_capped("most revenue") { engine.merchant_repository.most_revenue(3) }
    puts "most items..."
    time_capped("most items") { engine.merchant_repository.most_items(5) }
    puts "single merchant revenue..."
    time_capped("single merchant revenue") { engine.merchant_repository.find_by_name("Dicki-Bednar").revenue }
    puts "single merchant revenue for date..."
    time_capped("single merchant rev for date") { engine.merchant_repository.find_by_name("Willms and Sons").revenue(Date.parse "Fri, 09 Mar 2012") }
    puts "favorite customer..."
    time_capped("favorite customer") { engine.merchant_repository.find_by_name("Terry-Moore").favorite_customer }
    puts "pending invoices..."
    time_capped("pending invoices") { engine.merchant_repository.find_by_name("Parisian Group").customers_with_pending_invoices }

    #items
    puts "(items business intel)"
    time_capped("item most revenue") { engine.item_repository.most_revenue(5) }
    time_capped("most items") { engine.item_repository.most_items(37) }
    time_capped("best day") { engine.item_repository.find_by_name("Item Accusamus Ut").best_day }
  end

  def time_capped(label, &block)
    Timeout.timeout(TIMEOUT_THRESHOLD) do
      yield block
    end
  rescue Timeout::Error
    puts "#{label} timed out..."
  end
end

