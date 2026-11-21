/// A doctor in the "Find a doctor" list.
///
/// SAMPLE DATA ONLY: names and slots are placeholders until a real directory
/// of verified doctors exists (see the doctor portal plan). The photos are
/// AI-generated.
class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String city;
  final String nextSlot;
  final String photo;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.city,
    required this.nextSlot,
    required this.photo,
  });
}

const _p1 = 'assets/images/doctors/doctor1.png';
const _p2 = 'assets/images/doctors/doctor2.png';
const _p3 = 'assets/images/doctors/doctor3.png';

const sampleDoctors = <Doctor>[
  Doctor(
    id: 'fes-1',
    name: 'Dr. Name Surname',
    specialty: 'Endocrinologist',
    city: 'Fès',
    nextSlot: 'Tue, 10:30',
    photo: _p1,
  ),
  Doctor(
    id: 'fes-2',
    name: 'Dr. Name Surname',
    specialty: 'Endocrinologist',
    city: 'Fès',
    nextSlot: 'Wed, 14:00',
    photo: _p2,
  ),
  Doctor(
    id: 'fes-3',
    name: 'Dr. Name Surname',
    specialty: 'Endocrinologist',
    city: 'Fès',
    nextSlot: 'Thu, 09:30',
    photo: _p3,
  ),
  Doctor(
    id: 'cas-1',
    name: 'Dr. Name Surname',
    specialty: 'Endocrinologist',
    city: 'Casablanca',
    nextSlot: 'Mon, 11:00',
    photo: _p3,
  ),
  Doctor(
    id: 'cas-2',
    name: 'Dr. Name Surname',
    specialty: 'Endocrinologist',
    city: 'Casablanca',
    nextSlot: 'Wed, 10:00',
    photo: _p2,
  ),
  Doctor(
    id: 'cas-3',
    name: 'Dr. Name Surname',
    specialty: 'Endocrinologist',
    city: 'Casablanca',
    nextSlot: 'Fri, 09:30',
    photo: _p1,
  ),
  Doctor(
    id: 'rab-1',
    name: 'Dr. Name Surname',
    specialty: 'Endocrinologist',
    city: 'Rabat',
    nextSlot: 'Tue, 15:00',
    photo: _p1,
  ),
  Doctor(
    id: 'rab-2',
    name: 'Dr. Name Surname',
    specialty: 'Endocrinologist',
    city: 'Rabat',
    nextSlot: 'Thu, 11:30',
    photo: _p2,
  ),
  Doctor(
    id: 'mar-1',
    name: 'Dr. Name Surname',
    specialty: 'Endocrinologist',
    city: 'Marrakech',
    nextSlot: 'Wed, 09:30',
    photo: _p3,
  ),
  Doctor(
    id: 'mar-2',
    name: 'Dr. Name Surname',
    specialty: 'Endocrinologist',
    city: 'Marrakech',
    nextSlot: 'Fri, 14:30',
    photo: _p1,
  ),
];

/// Doctors of [specialty] in [city] (empty when none are listed).
List<Doctor> doctorsIn(String? city, {String specialty = 'Endocrinologist'}) =>
    city == null
    ? const []
    : sampleDoctors
          .where((d) => d.city == city && d.specialty == specialty)
          .toList();

Doctor doctorById(String id) =>
    sampleDoctors.firstWhere((d) => d.id == id, orElse: () => sampleDoctors[0]);
