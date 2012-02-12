root = exports ? this

ShoppingCartCheckout =
  updateCheckoutLinks: () ->
    if simpleCart.quantity > 0
      $('#cart-details .actions').show()
      console.log('update checkout links: not empty')
    else
      $('#cart-details .actions').hide()
      console.log('update checkout links: empty')
    ShoppingCartSummary.updateHeaderLinks()

  initCartSummary: () ->
    this.updateCheckoutLinks()

    $('#cart-details .simpleCart_empty').click( =>
      this.updateCheckoutLinks()
    )

    $('#cart-details .itemRemove a').click( =>
      this.updateCheckoutLinks()
    )

ShoppingCartSummary =
  updateHeaderLinks: () ->
    if simpleCart.quantity > 0
      console.log('update summary links: not empty')
      $('.cart-summary .empty').hide()
      $('.cart-summary .not-empty').show()
    else
      console.log('update summary links: empty')
      $('.cart-summary .not-empty').hide()
      $('.cart-summary .empty').show()



root.ShoppingCartCheckout = ShoppingCartCheckout
root.ShoppingCartSummary = ShoppingCartSummary
