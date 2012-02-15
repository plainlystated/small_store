root = exports ? this

ShoppingCartCheckout =
  shippingDomesticly: undefined

  init: () ->
    $('#cart-details .simpleCart_empty').click( =>
      this.update()
    )

    $('#cart-details .itemRemove a').click( =>
      this.update()
    )

    $('#shipping-to input').click( =>
      this.update()
    )
    this.update()

    $('#buy-paypal').click ->
      simpleCart.paypalCheckout()

    $('#buy-googlecheckout').click ->
      simpleCart.googleCheckout()

  calculateShipping: () ->
    shippingTo = $('#shipping-to input:checked').val()
    if shippingTo == undefined
      return false

    if shippingTo == 'world'
      this.shippingDomesticly = false
    else
      this.shippingDomesticly = true
    simpleCart.shipping()

  currency: (number) ->
    "$" + parseFloat(number).toFixed(2)

  updateTax: () ->
    shippingTo = $('#shipping-to input:checked').val()
    if shippingTo == undefined
      $('.taxCost').html("")
      return

    if shippingTo == 'illinois'
      simpleCart.taxRate = 0.095
    else
      simpleCart.taxRate = 0
    $('.taxCost').html(this.currency(simpleCart.taxRate * simpleCart.total))

  update: () ->
    this.updateTax()
    
    shippingCost = this.calculateShipping()
    if shippingCost
      $('.shippingCost').html(this.currency(shippingCost))
    else
      $('.shippingCost').html("")

    simpleCart.update()
    if simpleCart.quantity > 0
      $('#shipping-to').show()
    else
      $('#shipping-to').hide()

    if $('#shipping-to input:checked').size() > 0
      $('.cart-total .shipping-based').show()
      $('#cart-details .pay-actions a').show()
    else
      $('.cart-total .shipping-based value').html(" ")
      $('#cart-details .pay-actions a').hide()
    ShoppingCartSummary.updateHeaderLinks()

ShoppingCartSummary =
  updateHeaderLinks: () ->
    if simpleCart.quantity > 0
      $('.cart-summary .empty').hide()
      $('.cart-summary .not-empty').show()
    else
      $('.cart-summary .not-empty').hide()
      $('.cart-summary .empty').show()



root.ShoppingCartCheckout = ShoppingCartCheckout
root.ShoppingCartSummary = ShoppingCartSummary
