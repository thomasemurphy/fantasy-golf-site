# Seeds for The Feeley Tour Cup
# Run with: rails db:seed

# Create admin user
admin = User.find_or_initialize_by(email: "admin@feeleyturcup.com")
admin.name = "Commissioner"
admin.password = "changeme123!"
admin.password_confirmation = "changeme123!"
admin.admin = true
admin.approved = true
admin.entry_paid = true
admin.save!
puts "Admin user: #{admin.email} (password: changeme123!)"

# Seed 2026 PGA Tour season schedule
# 27 tournaments: Genesis Invitational (Feb 19) → BMW Championship (Aug 23)
EASTERN = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]

def lock_time(date)
  EASTERN.local(date.year, date.month, date.day, 6, 0, 0)
end

tournaments = [
  { week: 1,  name: "Genesis Invitational",             type: "regular",    start: "2026-02-19", end: "2026-02-22", purse: 20_000_000 },
  { week: 2,  name: "Mexico Open at Vidanta",           type: "regular",    start: "2026-02-26", end: "2026-03-01", purse: 8_700_000 },
  { week: 3,  name: "Puerto Rico Open",                 type: "regular",    start: "2026-02-26", end: "2026-03-01", purse: 4_000_000 },
  { week: 4,  name: "Cognizant Classic",                type: "regular",    start: "2026-03-05", end: "2026-03-08", purse: 8_700_000 },
  { week: 5,  name: "Arnold Palmer Invitational",       type: "side_event", start: "2026-03-05", end: "2026-03-08", purse: 20_000_000 },
  { week: 6,  name: "The Players Championship",         type: "regular",    start: "2026-03-12", end: "2026-03-15", purse: 25_000_000 },
  { week: 7,  name: "Valspar Championship",             type: "regular",    start: "2026-03-19", end: "2026-03-22", purse: 8_700_000 },
  { week: 8,  name: "Texas Children's Houston Open",    type: "regular",    start: "2026-03-26", end: "2026-03-29", purse: 9_500_000 },
  { week: 9,  name: "Masters Tournament",               type: "major",      start: "2026-04-09", end: "2026-04-12", purse: 20_000_000 },
  { week: 10, name: "RBC Heritage",                     type: "regular",    start: "2026-04-16", end: "2026-04-19", purse: 8_700_000 },
  { week: 11, name: "Zurich Classic of New Orleans",    type: "side_event", start: "2026-04-23", end: "2026-04-26", purse: 8_700_000 },
  { week: 12, name: "Myrtle Beach Classic",             type: "regular",    start: "2026-04-30", end: "2026-05-03", purse: 4_000_000 },
  { week: 13, name: "Wells Fargo Championship",         type: "regular",    start: "2026-05-07", end: "2026-05-10", purse: 9_500_000 },
  { week: 14, name: "PGA Championship",                 type: "major",      start: "2026-05-14", end: "2026-05-17", purse: 17_500_000 },
  { week: 15, name: "Charles Schwab Challenge",         type: "regular",    start: "2026-05-21", end: "2026-05-24", purse: 9_100_000 },
  { week: 16, name: "RBC Canadian Open",                type: "regular",    start: "2026-05-28", end: "2026-05-31", purse: 9_500_000 },
  { week: 17, name: "Memorial Tournament",              type: "side_event", start: "2026-06-04", end: "2026-06-07", purse: 20_000_000 },
  { week: 18, name: "U.S. Open",                        type: "major",      start: "2026-06-18", end: "2026-06-21", purse: 21_500_000 },
  { week: 19, name: "Travelers Championship",           type: "side_event", start: "2026-06-25", end: "2026-06-28", purse: 9_500_000 },
  { week: 20, name: "Rocket Mortgage Classic",          type: "regular",    start: "2026-07-02", end: "2026-07-05", purse: 8_700_000 },
  { week: 21, name: "John Deere Classic",               type: "regular",    start: "2026-07-09", end: "2026-07-12", purse: 8_000_000 },
  { week: 22, name: "The Open Championship",            type: "major",      start: "2026-07-16", end: "2026-07-19", purse: 17_000_000 },
  { week: 23, name: "3M Open",                          type: "regular",    start: "2026-07-23", end: "2026-07-26", purse: 8_700_000 },
  { week: 24, name: "FedEx St. Jude Championship",      type: "side_event", start: "2026-08-06", end: "2026-08-09", purse: 10_500_000 },
  { week: 25, name: "Wyndham Championship",             type: "regular",    start: "2026-08-13", end: "2026-08-16", purse: 7_400_000 },
  { week: 26, name: "FedEx St. Jude Championship",      type: "regular",    start: "2026-08-13", end: "2026-08-16", purse: 10_500_000 },
  { week: 27, name: "BMW Championship",                 type: "regular",    start: "2026-08-20", end: "2026-08-23", purse: 10_500_000 },
]

# Deduplicate by week number in case of overlapping
seen_weeks = []
tournaments.each do |t|
  next if seen_weeks.include?(t[:week])
  seen_weeks << t[:week]

  start_date = Date.parse(t[:start])
  end_date = Date.parse(t[:end])
  today = Date.current

  status = if today > end_date then "completed"
           elsif today >= start_date then "in_progress"
           else "upcoming"
           end

  Tournament.find_or_create_by!(week_number: t[:week]) do |tour|
    tour.name = t[:name]
    tour.start_date = start_date
    tour.end_date = end_date
    tour.purse_cents = (t[:purse] * 100).to_i
    tour.tournament_type = t[:type]
    tour.status = status
    tour.picks_locked_at = lock_time(start_date)
  end
end

puts "Seeded #{Tournament.count} tournaments"
