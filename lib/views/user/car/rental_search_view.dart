import 'package:dumum_tergo/views/user/car/result_search_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:dumum_tergo/viewmodels/user/rental_search_viewmodel.dart';
import 'package:dumum_tergo/views/user/car/rental_calendar_view.dart';
import 'package:dumum_tergo/views/user/car/search_location_page.dart';

class RentalSearchView extends StatelessWidget {
  const RentalSearchView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RentalSearchViewModel(),
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<RentalSearchViewModel>(
            builder: (context, viewModel, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SearchHeader(),
                  const SizedBox(height: 35),
                  const _LocationSection(),
                  const SizedBox(height: 35),
                  const _DateSection(),
                  const SizedBox(height: 16),
                  // const _DriverAgeSection(),
                  const Spacer(),
                  _buildSearchButton(context, viewModel),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context, RentalSearchViewModel viewModel) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: viewModel.isLoading
          ? null
          : () async {
              // Valider le formulaire avant de continuer
              viewModel.validateForm();
              
              if (viewModel.pickupLocation.isEmpty) {
                return; // Ne pas continuer si validation échoue
              }

              viewModel.setLoading(true);
              await viewModel.search();
              viewModel.setLoading(false);

              if (viewModel.searchResults.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultSearchView(
                      initialResults: viewModel.searchResults,
                      pickupLocation: viewModel.pickupLocation,
                      pickupDate: viewModel.pickupDate,
                      returnDate: viewModel.returnDate,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Aucun résultat trouvé'),
                  ),
                );
              }
            },
      child: viewModel.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              'Rechercher',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    ),
  );
}
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rechercher un véhicule de camping',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Trouvez le véhicule parfait pour vos aventures en plein air.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _LocationSection extends StatefulWidget {
  const _LocationSection({Key? key}) : super(key: key);

  @override
  _LocationSectionState createState() => _LocationSectionState();
}

class _LocationSectionState extends State<_LocationSection> {
  void _openSearchPage() async {
    final result = await Navigator.of(context, rootNavigator: true).push<String>(
      MaterialPageRoute(
        builder: (context) => SearchLocationPage(),
        fullscreenDialog: true,
      ),
    );

    if (result != null && result.isNotEmpty) {
      final parentViewModel = Provider.of<RentalSearchViewModel>(
        context,
        listen: false,
      );
      parentViewModel.setPickupLocation(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<RentalSearchViewModel>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lieu de prise en charge',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _openSearchPage,
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              border: Border.all(
                color: viewModel.showLocationError 
                    ? Colors.red 
                    : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    viewModel.pickupLocation.isNotEmpty
                        ? viewModel.pickupLocation
                        : 'Entrez une ville, un aéroport...',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                if (viewModel.showLocationError)
                  const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
        if (viewModel.showLocationError)
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Text(
              'Ce champ est obligatoire',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
class _DateSection extends StatefulWidget {
  const _DateSection({Key? key}) : super(key: key);

  @override
  _DateSectionState createState() => _DateSectionState();
}

class _DateSectionState extends State<_DateSection> {
  void _showCalendar(BuildContext context, bool isStartDate) {
    final viewModel =
        Provider.of<RentalSearchViewModel>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return RentalCalendarView(
          onPeriodSelected: (startDateTime, endDateTime) {
            viewModel.setPickupDate(startDateTime);
            viewModel.setReturnDate(endDateTime);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  String _formatDayOfWeek(DateTime date) {
    switch (date.weekday) {
      case 1:
        return 'lun.';
      case 2:
        return 'mar.';
      case 3:
        return 'mer.';
      case 4:
        return 'jeu.';
      case 5:
        return 'ven.';
      case 6:
        return 'sam.';
      case 7:
        return 'dim.';
      default:
        return '';
    }
  }

  String _formatMonth(DateTime date) {
    switch (date.month) {
      case 1:
        return 'janvier';
      case 2:
        return 'février';
      case 3:
        return 'mars';
      case 4:
        return 'avril';
      case 5:
        return 'mai';
      case 6:
        return 'juin';
      case 7:
        return 'juillet';
      case 8:
        return 'août';
      case 9:
        return 'septembre';
      case 10:
        return 'octobre';
      case 11:
        return 'novembre';
      case 12:
        return 'décembre';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<RentalSearchViewModel>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dates de location',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildDateSelector(
                  context, 'Départ', viewModel.pickupDate, true),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: _buildDateSelector(
                  context, 'Retour', viewModel.returnDate, false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelector(
      BuildContext context, String label, DateTime date, bool isStartDate) {
    final viewModel = Provider.of<RentalSearchViewModel>(context);
    final displayDate = isStartDate ? viewModel.pickupDate : viewModel.returnDate;

    return GestureDetector(
      onTap: () => _showCalendar(context, isStartDate),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayDate.day.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDayOfWeek(displayDate),
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatMonth(displayDate),
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${displayDate.hour.toString().padLeft(2, '0')}:${displayDate.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}