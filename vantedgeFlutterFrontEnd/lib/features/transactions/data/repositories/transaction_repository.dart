import 'package:vantedge/features/transactions/data/models/transaction_model.dart';
import 'package:vantedge/features/transactions/data/models/transfer_request.dart';
import 'package:vantedge/features/transactions/data/models/deposit_request.dart';
import 'package:vantedge/features/transactions/data/models/withdraw_request.dart';
import 'package:vantedge/features/transactions/data/models/account_statement_model.dart';
import 'package:vantedge/features/transactions/data/models/account_balance_model.dart';

abstract class TransactionRepository {

  Future<TransactionModel> transfer(TransferRequest request);

  Future<TransactionModel> deposit(DepositRequest request);

  Future<TransactionModel> withdraw(WithdrawRequest request);


  Future<AccountBalanceModel> getBalance(String accountNumber);


  Future<AccountStatementModel> getStatement(
    String accountNumber,
    DateTime startDate,
    DateTime endDate,
  );
}