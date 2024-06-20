export function getCurrentDayName() {
  const daysOfWeek = [
    "sunday",
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
  ];
  const currentDay = new Date().getDay();
  return daysOfWeek[currentDay];
}

export function addSecondsToDate(startDate: Date, secondsToAdd: number): Date {
  // Convert seconds to milliseconds
  const millisecondsToAdd = secondsToAdd * 1000;

  // Create a new date by adding milliseconds to the original date's time
  const newDate = new Date(startDate.getTime() + millisecondsToAdd);

  return newDate;
}
