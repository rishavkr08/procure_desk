# Refactor this Ruby on Rails class based on the mistakes and opportunities you see.
# There's no right or wrong answer, but there's plenty of room for improvement.
# Correct mistakes or logic errors. 
# Improve readability. Handle errors gracefully.
# Make it more Ruby-like. 
# Finally, add a few paragraphs explaining why you decided to make the changes you did.

# Assume Ruby 3.x and Rails 7.x

# Overview:
# This is a class for handling simplified invoices (requests for payment) 
# and payments. While there's room to expand the functionality, the classes have
# been kept simplified to reduce the scope of this effort.
# 1. Invoices can have multiple payments and can be partially paid.
# 2. Payments can be in the form of cash, check, or charge/credit card.
# 3. User-facing interactions and values are dollar amounts, but all currency 
#    values are transparently stored as pennies in the database.

# Primary Example Code:
# invoice = Invoice.create({ invoice_total: 200.00 })
# invoice.record_payment(100.00, :charge)

# Data Model
# invoice:
#   id: integer
#   invoice_total: integer (in pennies)
#   created_at: datetime
#   updated_at: datetime

# payment:
#   id: integer
#   invoice_id: integer
#   payment_method_id: integer 
#   amount: integer (in pennies)
#   created_at: datetime
#   updated_at: datetime


class Invoice
  has_many :payments, dependent: :destroy

  before_save :translate_invoice_total_to_cents

  validates :invoice_total, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def full_paid?
    amount_owed.zero?
  end

  def record_payment(amount_paid, payment_method)
    raise ArgumentError, "Invalid payment method" unless Payment.payment_methods.key?(payment_method.to_s)


    payments.create({ amount: (amount_paid * 100).to_i, payment_method: payment_method })
  end

  private
  def amount_owed
    invoice_total - payment.sum(:amount)
  end

  def translate_invoice_total_to_cents
    self.invoice_total = self.invoice_total * 100 if self.invoice_total.is_a?(Numeric)
  end
end

class Payment
  belongs_to :invoice

  enum payment_method: { cash: 0, check: 1, charge: 2 }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_method, inclusion: { in: payment_methods.keys, message: "Invalid payment method" }
end


# Improvements in Payment -
# 1. Fixed association by replacing has_one with belongs_to
# 2. Replaced METHODS for payment_method with enum
# 3. Removed custom methods to set payment_method
# 4. Removed custom validation method valid_payment_method?

# Improvements in Invoice -
# 1. Added dependent destroy in invoice, to remove payments when invoice is destroyed
# 2. Replaced before_create with before_save to handle update as well
# 3. Added numeric validation for invoice_total
# 4. Fixed full_paid? method as it should true when amount_owed method returns 0
# 5. Added exception handling for payment_method param to check if is present in the enum in Payment
# 6. Fixed translate_invoice_total_to_cents to save updated data in invoice_total
