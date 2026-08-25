import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/game.dart';
import '../models/listing.dart';
import '../models/todo.dart';
import '../services/bgg_service.dart';
import '../services/game_repository.dart';
import '../services/listing_repository.dart';
import '../services/settings_repository.dart';
import '../services/todo_repository.dart';

class AppDataProvider extends ChangeNotifier {
  final String userId;
  final GameRepository gameRepo;
  final TodoRepository todoRepo;
  final ListingRepository listingRepo;
  final SettingsRepository settingsRepo;
  final BggService bggService;

  AppDataProvider({
    required this.userId,
    required this.gameRepo,
    required this.todoRepo,
    required this.listingRepo,
    required this.settingsRepo,
    required this.bggService,
  });

  List<Game> games = [];
  AppSettings? settings;
  final Map<String, List<GameTodo>> todosByGame = {};
  final Map<String, Listing?> listingByGame = {};

  bool loading = false;
  String? error;
  bool syncingBgg = false;
  String? bggSyncMessage;

  List<Game> get zumEntscheiden =>
      games.where((g) => g.status == GameStatus.unentschieden).toList();

  List<Game> get zumVerkauf =>
      games.where((g) => g.status == GameStatus.verkaufen).toList();

  List<Game> get behalten =>
      games.where((g) => g.status == GameStatus.behalten).toList();

  List<Game> get verkauft =>
      games.where((g) => g.status == GameStatus.verkauft).toList();

  List<Game> get rechercheVeraltetListe => games
      .where((g) =>
          g.status != GameStatus.verkauft &&
          g.rechercheVeraltet(settings?.rechercheIntervallTage ?? 90))
      .toList();

  Future<void> loadAll() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      settings = await settingsRepo.fetchOrCreate(userId);
      games = await gameRepo.fetchAll(userId);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshGames() async {
    games = await gameRepo.fetchAll(userId);
    notifyListeners();
  }

  Future<bool> syncBgg({String? usernameOverride}) async {
    final username = usernameOverride ?? settings?.bggUsername;
    if (username == null || username.trim().isEmpty) {
      error = 'Bitte zuerst einen BGG-Benutzernamen in den Einstellungen eintragen.';
      notifyListeners();
      return false;
    }
    syncingBgg = true;
    error = null;
    bggSyncMessage = null;
    notifyListeners();
    try {
      final items = await bggService.fetchCollection(username);
      final neu = await gameRepo.syncFromBgg(userId, items);
      await refreshGames();
      bggSyncMessage =
          '$neu neue Spiele importiert, ${items.length} insgesamt abgeglichen.';
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      syncingBgg = false;
      notifyListeners();
    }
  }

  Future<void> decide(Game game, GameStatus status) async {
    await gameRepo.updateStatus(game.id, status);
    await refreshGames();
  }

  Future<void> updateKaufpreis(String gameId, double? kaufpreis) async {
    await gameRepo.updateKaufpreis(gameId, kaufpreis);
    await refreshGames();
  }

  Future<void> updateRecherche(String gameId, {required double min, required double max}) async {
    await gameRepo.updateRecherche(gameId, min: min, max: max);
    await refreshGames();
  }

  Future<void> updateAngebotspreis(String gameId, double? angebotspreis) async {
    await gameRepo.updateAngebotspreis(gameId, angebotspreis);
    await refreshGames();
  }

  Future<void> updateZustand(String gameId, String zustand) async {
    await gameRepo.updateZustand(gameId, zustand);
    await refreshGames();
  }

  Future<void> updateSchmerzgrenzeOverride(String gameId, double? prozent) async {
    await gameRepo.updateSchmerzgrenzeOverride(gameId, prozent);
    await refreshGames();
  }

  Future<void> updateVerkaufstext(String gameId, String verkaufstext) async {
    await gameRepo.updateVerkaufstext(gameId, verkaufstext);
    await refreshGames();
  }

  Future<List<GameTodo>> loadTodos(Game game) async {
    if (settings == null) return [];
    final todos = await todoRepo.syncForGame(game, settings!);
    todosByGame[game.id] = todos;
    notifyListeners();
    return todos;
  }

  Future<void> toggleTodo(GameTodo todo) async {
    await todoRepo.setDone(todo.id, !todo.done);
    final list = todosByGame[todo.gameId];
    if (list != null) {
      todosByGame[todo.gameId] = [
        for (final t in list)
          if (t.id == todo.id)
            GameTodo(
              id: t.id,
              userId: t.userId,
              gameId: t.gameId,
              key: t.key,
              label: t.label,
              done: !t.done,
              createdAt: t.createdAt,
            )
          else
            t,
      ];
      notifyListeners();
    }
  }

  Future<Listing?> loadListing(String gameId) async {
    final listing = await listingRepo.fetchActiveForGame(gameId);
    listingByGame[gameId] = listing;
    notifyListeners();
    return listing;
  }

  Future<void> createListing(Game game, DateTime datum) async {
    final listing =
        await listingRepo.create(userId: userId, gameId: game.id, inseratDatum: datum);
    listingByGame[game.id] = listing;
    notifyListeners();
  }

  Future<void> updateListingStatus(Listing listing, ListingStatus status) async {
    await listingRepo.updateStatus(listing.id, status);
    await loadListing(listing.gameId);
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    await settingsRepo.update(newSettings);
    settings = newSettings;
    notifyListeners();
  }

  Future<void> updateGameField(String gameId, Future<void> Function() write) async {
    await write();
    await refreshGames();
  }
}
