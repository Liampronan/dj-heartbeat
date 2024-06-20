export function getLastSunday() {
  const today = new Date();
  // Convert to UTC date to ensure consistency
  const dayOfWeek = today.getUTCDay();
  const difference = dayOfWeek * 24 * 60 * 60 * 1000; // Convert days to milliseconds
  const lastSunday = new Date(today.getTime() - difference);
  // Adjust to the beginning of the day in UTC
  lastSunday.setUTCHours(0, 0, 0, 0);
  return lastSunday;
}

export function getTwoSundaysAgo() {
  const today = new Date();
  const dayOfWeek = today.getUTCDay();
  const differenceToLastSunday = dayOfWeek * 24 * 60 * 60 * 1000; // Convert days to milliseconds
  const twoWeeksInMilliseconds = 7 * 24 * 60 * 60 * 1000;
  const twoSundaysAgo = new Date(
    today.getTime() - differenceToLastSunday - twoWeeksInMilliseconds
  );
  // Adjust to the beginning of that day in UTC
  twoSundaysAgo.setUTCHours(0, 0, 0, 0);
  return twoSundaysAgo;
}

export function getStartOfTodayPacific() {
  const now = new Date();

  const pacificTime = now.toLocaleString("en-US", {
    timeZone: "America/Los_Angeles",
  });

  const pacificDate = new Date(pacificTime);

  pacificDate.setHours(0, 0, 0, 0);

  return pacificDate;
}

export function getDayOfWeekTimeOfDayText() {
  const now = new Date();

  const dayOfWeek = now.toLocaleString("en-US", {
    timeZone: "America/Los_Angeles",
    weekday: "long",
  });
  const hour = now.toLocaleString("en-US", {
    timeZone: "America/Los_Angeles",
    hour: "numeric",
    hour12: true,
  });

  let timeOfDay;
  const hourNumber = parseInt(hour, 10);
  if (hour.includes("AM")) {
    timeOfDay = "morning";
  } else if (hourNumber < 6 || (hour.includes("PM") && hourNumber === 12)) {
    timeOfDay = "afternoon";
  } else {
    timeOfDay = "evening";
  }

  return `${dayOfWeek.toLowerCase()} ${timeOfDay}`;
}
