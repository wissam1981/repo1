import 'package:flutter/material.dart';
import '../models/contract.dart';
import '../services/api_client.dart';
import '../services/file_pick_helper.dart';

/// ChangeNotifier that owns the list of the user's contracts and the currently
/// selected contract.
///
/// Screens consume this provider via [Consumer] or [Provider.of]; no direct
/// HTTP calls are made from the UI layer.
class ContractsProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  List<Contract> _contracts = [];
  Contract? _currentContract;
  bool _isLoading = false;
  String? _error;

  ContractsProvider(this._apiClient);

  List<Contract> get contracts => List.unmodifiable(_contracts);
  Contract? get currentContract => _currentContract;

  /// The contract the journey/tutor/progress screens operate on.
  /// Defaults to the first contract until the user switches.
  Contract? get activeContract {
    if (_currentContract != null) {
      // Re-resolve against the latest loaded list so clause state is fresh.
      for (final c in _contracts) {
        if (c.id == _currentContract!.id) return c;
      }
    }
    return _contracts.isNotEmpty ? _contracts.first : null;
  }
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetches the user's contract list from the backend.
  Future<void> loadContracts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.getList('/contracts');
      _contracts = response
          .map((c) => Contract.fromJson(c as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // If load fails (e.g., network error), just clear loading state
      // User will see empty list but can still upload files
      _error = null; // Don't show error, just silently continue
      _contracts = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Uploads a new contract from a [PickedFile] and adds it to the list.
  Future<Contract> uploadContract({
    required String title,
    required PickedFile file,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.postMultipart(
        '/contracts',
        {'title': title},
        {file.name: file.bytes},
      );
      final contract = Contract.fromJson(response);
      _contracts = [..._contracts, contract];
      _currentContract = contract;
      _isLoading = false;
      notifyListeners();
      return contract;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Sets the contract that detail screens should display.
  void selectContract(Contract contract) {
    _currentContract = contract;
    notifyListeners();
  }

  /// Polls backend processing progress for an uploading contract.
  /// Returns {status, stage, done, total, percent}.
  Future<Map<String, dynamic>> getProgress(int contractId) async {
    return _apiClient.get('/contracts/$contractId/progress');
  }

  /// Marks a clause complete in the learning journey and refreshes state.
  Future<void> completeClause(int contractId, int clauseId) async {
    await _apiClient
        .post('/contracts/$contractId/clauses/$clauseId/complete', {});
    // Update local state so the journey unlocks the next clause immediately.
    _contracts = _contracts.map((c) {
      if (c.id != contractId) return c;
      final updated = Contract(
        id: c.id,
        title: c.title,
        fileUrl: c.fileUrl,
        status: c.status,
        clauses: c.clauses
            .map((cl) => cl.id == clauseId
                ? Clause(
                    id: cl.id,
                    order: cl.order,
                    originalText: cl.originalText,
                    simpleEn: cl.simpleEn,
                    arabic: cl.arabic,
                    keyTerms: cl.keyTerms,
                    completed: true,
                    isDefinition: cl.isDefinition,
                    relatedOrders: cl.relatedOrders,
                  )
                : cl)
            .toList(),
      );
      if (_currentContract?.id == c.id) _currentContract = updated;
      return updated;
    }).toList();
    notifyListeners();
  }
}
