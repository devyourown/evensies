/// Event type strings from docs/API.md.
abstract final class EventTypes {
  static const groupCreated = 'group.created';
  static const groupUpdated = 'group.updated';
  static const memberAdded = 'member.added';
  static const memberLinked = 'member.linked';
  static const memberRemoved = 'member.removed';
  static const expenseCreated = 'expense.created';
  static const expenseUpdated = 'expense.updated';
  static const expenseDeleted = 'expense.deleted';
  static const expenseRestored = 'expense.restored';
  static const commentAdded = 'comment.added';
  static const commentDeleted = 'comment.deleted';
  static const paymentCreated = 'payment.created';
  static const paymentDeleted = 'payment.deleted';
  static const paymentConfirmed = 'payment.confirmed';
}
