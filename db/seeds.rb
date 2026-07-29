Plan.find_or_create_by!(slug: "starter") do |p|
  p.name               = "Starter"
  p.analyses_per_month = 50
  p.price_cents        = 29_700
  p.active             = true
end

Plan.find_or_create_by!(slug: "growth") do |p|
  p.name               = "Growth"
  p.analyses_per_month = 300
  p.price_cents        = 79_700
  p.active             = true
end

Plan.find_or_create_by!(slug: "enterprise") do |p|
  p.name               = "Enterprise"
  p.analyses_per_month = nil
  p.price_cents        = 0
  p.active             = true
end
