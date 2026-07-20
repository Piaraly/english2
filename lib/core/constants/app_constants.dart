class AppConstants {
  const AppConstants._();

  static const levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const skills = ['Grammar', 'Vocabulary', 'Listening', 'Speaking', 'Reading', 'Writing'];
  static const eventTypes = ['Conteúdo', 'Imersão', 'Speaking', 'Revisão', 'Quiz', 'Exercício', 'Ensinar amigo'];
  static const materialStatuses = ['active', 'waitlist', 'completed', 'archive'];
  static const materialStatusLabels = {
    'active': 'Ativo',
    'waitlist': 'Lista de espera',
    'completed': 'Concluído',
    'archive': 'Arquivo',
  };
  static const recordingPrompts = [
    'Describe your day in 60 seconds.',
    'Explain what you studied today.',
    'Tell a short story about a mistake you learned from.',
    'Describe a medicine, technology or scientific idea in simple English.',
    'Give your opinion about a series or film you watched.',
    'Imagine you are teaching this grammar point to a friend.',
  ];
}
