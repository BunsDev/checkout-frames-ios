//
//  CardNumberViewModel.swift
//  Frames
//
//  Created by Harry Brown on 07/07/2022.
//  Copyright © 2022 Checkout. All rights reserved.
//

import Checkout

protocol CardNumberViewModelDelegate: AnyObject {
  func update(cardNumber: String, scheme: Card.Scheme)
}

protocol CardNumberViewModelProtocol {
  func validate(cardNumber: String) -> Constants.Bundle.SchemeIcon?
  func eagerValidate(cardNumber: String) -> (newTextFieldValue: String, schemeIcon: Constants.Bundle.SchemeIcon)?
}

class CardNumberViewModel {
  weak var delegate: CardNumberViewModelDelegate?

  private let cardUtils = CardUtils()
  private let cardValidator: CardValidating

  init(cardValidator: CardValidating) {
    self.cardValidator = cardValidator
  }
}

extension CardNumberViewModel: CardNumberViewModelProtocol {
  func validate(cardNumber rawText: String) -> Constants.Bundle.SchemeIcon? {
    let cardNumber = cardUtils.removeNonDigits(from: rawText)

    switch cardValidator.validate(cardNumber: cardNumber) {
    case .failure, .success(.unknown):
      delegate?.update(cardNumber: cardNumber, scheme: .unknown)
      return nil
    case .success(let scheme):
      delegate?.update(cardNumber: cardNumber, scheme: scheme)
      return Constants.Bundle.SchemeIcon(scheme: scheme)
    }
  }

  func eagerValidate(cardNumber rawText: String) -> (newTextFieldValue: String, schemeIcon: Constants.Bundle.SchemeIcon)? {
    let cardNumber = cardUtils.removeNonDigits(from: rawText)

    if let scheme = shouldAllowChange(cardNumber: cardNumber) {
      // using CardUtils until we add this functionality into Checkout SDK
      return (cardUtils.format(cardNumber: cardNumber, scheme: scheme), Constants.Bundle.SchemeIcon(scheme: scheme))
    }

    return nil
  }

  private func shouldAllowChange(cardNumber: String) -> Card.Scheme? {
    switch cardValidator.eagerValidate(cardNumber: cardNumber) {
    case .success(let scheme):
      return scheme
    case .failure(let error):
      return handleValidationError(error: error)
    }
  }

  private func handleValidationError(error: ValidationError.EagerCardNumber) -> Card.Scheme? {
    switch error {
    case .tooLong:
      return nil
    case .invalidScheme:
      return .unknown
    case .cardNumber(let cardNumberError):
      switch cardNumberError {
      case .invalidCharacters:
        return nil
      }
    }
  }
}
