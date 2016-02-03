package MT::MoreAnalytics::L10N::fr;

use strict;
use utf8;
use base 'MT::MoreAnalytics::L10N::en_us';
use vars qw( %Lexicon );

%Lexicon = (

    # config.yaml
    'MoreAnalytics' => 'MoreAnalytics',
    'Provides more features for Google Analytics.'
        => 'Services avancés pour Google Analytics',
    "ideaman's Inc." => 'ideaman’s Inc.',
    'Edit Custom KPI Widget' => 'Éditer le widget KPI',
    'Manage Aggregation Period' => 'Gérer la période d’agrégation',
    'API Playground' => 'Assistant API',
    'Yesterday(The last day)' => 'Hier',
    'Days before' => 'jours précédents',
    'New Period' => 'Nouvelle période',
    'Google Analytics' => 'Google Analytics',
    'API Playground' => 'Assistant API',
    'Custom Widget' => 'Widget personnalisé',
    'MoreAnalytics Updates Object Stats' => 'Mise à jour des stats objets MoreAnalytics ',
    'MoreAnalytics Cleanup Cache' => 'Vider le cache MoreAnalytics ',
    'Aggregation Period' => q{Période d’agrégation},
    'Aggregation Periods' => q{Périodes d’agrégation},
    'period' => 'période',
    'periods' => 'périodes',

    # more_analytics.yaml
    'Visits' => 'Visites',
    'Yesterday' => 'Hier',
    'Last A Week' => 'Semaine dernière',

    # themes.yaml
    'Simple Access Report'
        => 'Rapport d’accès simple',
    'A simple access stats report for any site.'
        => 'Un rapport simplifié d’accès aux sites',
    'About This Template' => 'À propos de ce gabarit',
    'This template is not used in this theme, created as a placeholder to customize.'
        => 'Ce gabarit n’est pas utilisé dans ce thème, il sert d’exemple à personnaliser',
    'About This Theme' => 'À propos de ce thème',
    'Access reporting theme provided as a part of MoreAnalytics plugin.'
        => 'Thème pour rapports de statistiques fourni avec le plugin MoreAnalytics.',

    'Config Template Module' => 'Configurer le module de gabarit',
    'Global Header' => 'Entête global',
    'Global Footer' => 'Pied de page global',
    'Monthly Archives' => 'Archives mensuelles',
    'Recent Entries' => 'Notes récentes',
    'Entry Digest' => 'Résumé de la note',
    'Entry Header' => 'Entête de la note',
    'Compared Report Widget' => 'Widget de rapports comparés',
    'Metric Panel' => 'Panneau de métriques',

    'Entry Body' => 'Corps de la note',
    'Summary Stats' => 'Statistiques sommaires',
    'Mobile Stats' => 'Statistiques Mobile',
    'User Agents' => 'Navigateurs',
    'Traffic Stats' => 'Statistiques de traffic',
    'Search Keywords' => 'Mots-clés de recherche',
    'Referrers' => 'Sources',
    'User Satisfaction' => 'Satisfaction utilisateur',
    'Popular Contents' => 'Contenus populaires',
    'Goal Conversions' => 'Objectifs de conversion',
    'EC Conversions' => 'Conversions e-commerce',

    'Reporting Widgets In Each Entry' => 'Widgets de rapport pour chaque note',
    'Reporting Widgets In Entry Listing' => 'Widgets de rapport pour liste de notes',

    'Processing Start Date' => 'Début de la période',
    'Processing End Date' => 'Fin de la période',

    'Feed - Recent Reports' => 'Flux — Rapports récents',
    'Report Listing' => 'Liste des rapports',
    'Report Archive' => 'Archives des rapports',

    'Read More' => 'Lire la suite',
    'Weekly Report' => 'Rapport hebdomadaire',
    'Monthly Report' => 'Rapport mensuel',
    'Sidebar' => 'Barre latérale',

    'Reported on [_1]' => 'Publié le : [_1]',
    'Reported by [_1]' => 'Publié par : [_1]',
    '[_1] ~ [_2]' => '[_1] 〜 [_2]',
    'This Time' => 'Période',
    'Previous' => 'Précédemment',

    'Visits' => 'Visites',
    'Percentage' => 'Pourcentage',
    'Rest' => 'Reste',
    'Total' => 'Total',

    'OS' => 'OS',
    'Ver.' => 'Version',
    'Browser' => 'Navigateur',

    'Keyword' => 'Mot-clé',

    'Referrer' => 'Source',
    'Referrers' => 'Sources',

    'Page' => 'Page',
    'PV' => 'PV',
    'Visitors' => 'Visiteurs',

    'New Visits' => 'Nouvelles visites',
    'Avg. PV' => 'PV moy.',
    'Avg. Page Stay' => 'Durée moy. / page',
    'Avg. Site Stay' => 'Durée moy. / visite',

    'Allow All' => 'Permettre à tous',
    'Deny All' => 'Interdire à tous',

    # tmpl/playground.tmpl
    'Google Analytics API Playground' => 'Assistant API Google Analytics',
    'Profile' => 'Profil',
    'Profiles' => 'Profils',
    'Metric' => 'Métrique',
    'Metrics' => 'Métriques',
    'Dimension' => 'Dimension',
    'Dimensions' => 'Dimensions',
    'Fields' => 'Champs',
    'Filters' => 'Filtres',
    'Options' => 'Options',
    'Sort' => 'Classement',
    'Set as below' => 'Configurer comme ci-après',
    'Start Date' => 'Date de début',
    'End Date' => 'Date de fin',
    'Start Index' => 'Index de démarrage',
    'Max Results' => 'Limite de résultats',
    'Result Table' => 'Table de résultats',
    'Template Snipet' => 'Morceau de gabarit',
    'Run Query' => 'Lancer la requête',
    'Example Template' => 'Gabarit d’exemple',
    '(Asc)' => '(asc)',
    '(Desc)' => '(déc)',
    '\\(Asc\\)' => '\\(asc\\)',
    '\\(Desc\\)' => '\\(déc\\)',
    'Unknown' => 'Inconnu',
    'Reload' => 'Recharger',

    # tmpl/config/system.tmpl
    'Update Object Stats' => 'Mettre à jour les stats objets',
    'Update Frequency' => 'Fréquence de mise à jour',
    'Maximum Results Limit' => 'Nombre maximum de résultats',
    'Maximum number of results that should be returned in one request.' => 'Nombre maximum de résultats renvoyés dans une réponse.',
    'Minutes' => 'Minutes',
    'Cleanup Cache' => 'Vider le cache',
    'Cleanup Frequency' => 'Fréquence de nettoyage',
    'Limit Size' => 'Limite de taille',
    'Scheduled tasks clenup caches over this size from older.'
        => 'Tâche programmée de nettoyage des caches dépassant cette taille.',
    'MB' => 'MO',
    'Drop All Caches' => 'Vider tous les caches',
    'Processing...' => 'Traitement en cours…',
    'Are you sure to drop all caches?' => 'Voulez-vous vraiment vider tous les caches ?',
    'Error: Invalid result.' => 'Erreur : résultat invalide.',
    'Error:' => 'Erreur :',

    # tmpl/config/blog.tmpl
    'DESCRIPTION_KEYWORD_ASSISTANT'
        => 'l’assistant de mots-clés est un widget affiché dans la barre latérale de l’éditeur des notes et des pages. Vous pouvez afficher les mot-clés populaires, pour aider à la création de contenu.',

    'Ignore Keywords - Perfect Match' => 'Mots-clés à ignorer (exactement)',
    'Ignore Keywords' => 'Mots-clés à ignorer',
    'Inherited Ignore Keywords' => 'Mots-clés à ignorer (hérités)',
    'Enter at most 5 keywords to ignore as each lines. (not provided) is always ignored.'
        => 'Entrer au plus 5 mots-clés à ignorer, un par ligne. (not provided) est toujours ignoré.',

    'Ignore Keywords - Regex. Match' => 'Mots-clés à ignorer (expression régulière)',
    'Ignore Regex.' => 'Expression régulière à ignorer',
    'Inherited Ignore Regex.' => 'Expression régulière à ignorer (héritée)',
    'Enter keyword regular expression to ignore. ex: (Movable|Type|MT)'
        => 'Entrer l’expression régulière à ignorer. Exemple : (Movable|Type|MT)',

    'Inherit Settings' => 'Hériter les paramètres',
    'Inherit from system' => 'Hériter de ceux du système',
    'Inherit from website' => 'Hériter de ceux du site web',
    'Not inherit, define at here' => 'Ne pas hériter, les définir ici',

    '(No Settings)' => '(Aucun paramètre)',

    'Data API Policy' => 'Politique API Data',
    'Select how to response Data API request about Google Analytics.'
        => 'Politique de réponse aux requêtes AIP Data sur Google Analytics',
    'If you no have plan to use Data API, select "Deny All".'
        => 'Si vous n’utilisez pas l’API Data, choisissez "Interdire à tous".',

    'API Call' => 'Appel API',
    'Policy for /sites/:site_id/more-analytics endpoint.'
        => 'Politique d’accès API /sites/:site_id/more-analytics',
    'Object Stats' => 'Stats objets',
    'Policy if contain access stats to each object response data.'
        => 'Inclure les statistiques d’accès dans les données de réponse pour chaque objet.',

    'Inherit from Parent - [_1]' => 'Hériter du parent ([_1])',

    # tmpl/edit_ma_period.tmpl
    'Create Aggregation Period' => 'Créer une période d’agrégation',
    'Edit Aggregation Period' => 'Éditer la période d’agrégation',
    'Save this period (s)' => 'Enregistrer cette période (s)',
    'Delete this period (x)' => 'Supprimer cette période (x)',
    'Aggregate from' => 'Agréger à partir de',
    'Aggregate to' => 'Agréger jusqu’à',
    'days before' => 'jours avant',
    'Basename' => 'Nom de base',
    'Your changes have been saved.' => 'Vos modifications ont été enregistrées.',
    'Name' => 'Nom',
    'Description' => 'Description',
    "Warning: Changing this period's basename may require changes to existing templates."
        => 'Attention : modifier le nom de base peut obliger à modifier des gabarits existants.',
    'Save' => 'Enregistrer',
    'Delete' => 'Supprimer',

    '_PREFIX_FROM' => 'De ',
    '_SUFFIX_FROM' => ' ',
    '_PREFIX_TO' => 'À ',
    '_SUFFIX_TO' => ' ',

    # tmpl/keyword_assistant.tmpl
    'Keyword Assistant' => 'Assistant mots-clés',
    'Show Keywords' => 'Montrer les mots-clés',
    'Hide Keywords' => 'Masquer les mots-clés',
    'Open Options' => 'Ouvrir les options',
    'Close Options' => 'Fermer les options',

    'Unknown metric.' => 'Métrique inconnue.',
    'Unknown term.' => 'Terme inconnu.',
    'Unknown blog or website.' => 'Blog ou site inconnu.',
    'Unknown period as term: id=[_1].' => 'Période inconnue : id=[_1]',

    'Metric' => 'Métrique',
    'Term' => 'Terme',
    'Keyword Count' => 'Nb. de mot-clé',

    'Save To All Blogs' => 'Enregistrer pour tous les blogs',
    'Save As Default' => 'Enregistrer comme modèle par défaut',
    'Close' => 'Fermer',
    'Saved.' => 'Enregistré.',

    'JSON parse error.' => 'Erreur de lecture JSON.',
    'Invalid result format.' => 'Format de résultat invalide.',

    # lib/MT/MoreAnalytics/Tags.pm
    '[_1] requires blog context.' => '[_1] exige un contexte de blog.',
    'Google Analytics is not ready for blog or website ID:[_1]'
        => 'Google Analytics n’est pas configuré pour le site ou le blog (ID:[_1])',
    'Period [_1] is not found.' => 'Période [_1] introuvable.',
    'items in results is not an array.' => 'les éléments résultants ne forment pas un tableau.',
    '[_1] is not used in mt:GAReport context.' => '[_1] est inutilisé dans le contexte de mt:GAReport.',
    '[_1] requires [_2] attribute.' => '[_1] exige un attribut [_2].',
    '[_1] can not detect path info.' => '[_1] impossible de détecter le chemin (pathinfo).',
    '[_1] is not found.' => '[_1] est introuvable.',
    'Aggregation period [_1] not found.' => 'La préiode d’agrégation [_1] est introuvable.',

    # lib/MT/MoreAnalytics/Tags/Util.pm
    'The value "[_3]" in [_2] attribute of [_1] tag must be valid date format.'
        => 'La valeur "[_3]" dans l’attribut [_2] du tag [_1] tag doit être un format de date valide.',

    # tmpl/playground/profiles.tmpl
    'Default' => 'Défault',

    # lib/MT/MoreAnalytics/Tasks.pm
    'MoreAnalytics updated object stats. [_1] blog(s), [_2] period(s), [_3] query(ies), [_4] stat(s).'
        => 'Mise à jour des stats objets MoreAnalytics : [_1] blog(s), [_2] période(s), [_3] req. API, [_4] statistique(s).',
    'MoreAnalytics cleanup cache. [_1] cache(s), [_2] bytes cleanup, limit to [_3] bytes, currently total [_4] bytes.'
        => 'Nettoyage du cache MoreAnalytics : [_1] cache(s), [_2] octets libérés, limite à [_3] octets, total occupé [_4] octets.',
    'MoreAnalytics checked cache size, but current total [_1] bytes is within the limit of [_2] bytes.'
        => 'La taille du cache de [_1] octets est dans la limite des [_2] octets définie pour MoreAnalytics.',

    # lib/MT/MoreAnalytics/Cache.pm
    'MoreAnalytics Cache' => 'Cache MoreAnalytics',
    'MoreAnalytics Caches' => 'Caches MoreAnalytics',

    # lib/MT/MoreAnalytics/Period.pm
    'Aggregation Periods' => 'Périodes d’agrégation',
    'Name is required.' => 'Le nom est requis.',
    'Basename is required.' => 'Le nom de base est requis.',
    'Basename should be consisted with alphabets, numbers or underscore.'
        => 'Le nom de base (identifiant unique) doit contenir des caractères alphanumériques, des chiffres ou le caractère souligné (_).',
    '"Aggregate from" has no method.' => '"Agréger de" n’a pas de méthode.',
    '"Aggregate to" has no method.' => '"Agréger à" n’a pas de méthode.',
    '"Aggregate from" has probrem: [_1]' => '"Agréger de" a un problème : [_1]',
    '"Aggregate to" has probrem: [_1]' => '"Agréger à" a un problème : [_1]',
    'Summary' => 'Résumé',
    '[_1] - [_2]' => '[_1] - [_2]',
    'From "[_1]" to "[_2]".' => 'De "[_1]" à "[_2]".',
    'Unknown period method: [_1]' => 'Méthode de période inconnue : [_1]',
    'Evaluation' => 'Évaluation',

    # lib/MT/MoreAnalytics/App/CMS.pm
    'Google Analytics is not ready for blog or website ID:[_1]'
        => 'Google Analytics n’est pas configuré pour le site ou le blog (ID:[_1]).',
    'Droped all caches.' => 'Tous les caches ont été vidés.',
    'GA:Aggregation Period' => 'GA : Période agrégée',
    'GA:Pageviews' => 'GA : Pages vues',
    '%0.2f Sec.' => '%0.2fs',
    '_DATE_FORMAT' => '%d%m%Y',

    # lib/MT/MoreAnalytics/CMS/Listing.pm
    ' - Uncollected' => ' - Non collecté',

    # lib/MT/MoreAnalytics/CMS/KeywordAssitant.pm
    'Unknown blog.' => 'Blog inconnu.',
    'Unknown user.' => 'Utilisateur inconnu',

    # lib/MT/MoreAnalytics/CMS/Widget.pm
    'Permission denigied.' => 'Autorisation refusée.',
    'Unknown action' => 'Action inconnue',

    # lib/MT/MoreAnalytics/ObjectStat.pm
    'Object Statistics' => 'Statistiques objet',

    # lib/MT/MoreAnalytics/CMS/Period.pm
    'Basename is reuquired.' => 'Le nom de base est requis.',
    'Aggregation period basename of [_1] is already exists. Basename should be unique.'
        => 'Le nom de base de la période [_1] existe déjà, il doit être unique.',
    'This period is from [_1] = [_2] to [_3] = [_4].'
        => 'Cette période va de [_1] = [_2] à [_3] = [_4].',

    # tmpl/widget/custom_main_widget.tmpl
    'Custom Main Widget' => 'Statistiques personnalisées',
    'Preview this template (s)' => 'Prévisualiser ce gabarit (s)',
    'Preview' => 'Prévisualiser',
    'Save' => 'Enregistrer',
    'Close editing (s)' => 'Fermer l’éditeur (s)',
    'Close' => 'Fermer',
    'Cancel' => 'Annuler',
    "Click 'Edit' link to start editing template to show in this widget."
        => "Cliquez sur 'Éditer' pour éditer le gabarit et personnaliser le contenu de ce widget.",
    'Edit' => 'Éditer',
    'Your template for widget has been saved.' => 'Le gabarit de ce widget a été enregistré.',
    'Parsing JSON has an error.' => 'Erreur de lecture JSON.',

    # tmpl/widget/custom_sidebar_widget.tmpl
    'Custom Sidebar' => 'Barre latérale personnalisée',

    # lib/MT/MoreAnalytics/CMS/Playground.pm
    'Blog required.' => 'Blog requis.',
    'Request needs a metric at least.' => 'La requête exige au moins une métrique.',
    'Permission denied.' => 'Autorisation refusée.',
    'Unknown period [_1]' => 'Période inconnue : [_1]',
    'Google Analytics is not set up for this blog or website.'
        => 'Google Analytics n’est pas configuré pour ce site ou ce blog.',
    'Cannot create MoreAnalytics provider object.'
        => 'Impossible de créer un objet fournisseur pour MoreAnalytics.',

    # lib/MT/MoreAnalytics/PeriodMethod/Common.pm
    'Days before' => 'Jours avant',
    'Yesterday(The last day)' => 'Hier',
    '[_1] days before' => '[_1] jours avant',
    'Enter an integer zero or over.' => 'Entrez un entier supérieur ou égal à zéro.',

);

1;
