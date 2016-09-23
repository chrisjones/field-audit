def load_builders(city)
  if city == "birmingham"
    return BIRMINGHAM_BUILDERS
  elsif city == "nashville"
    return NASHVILLE_BUILDERS
  else
    return nil
  end
end

def load_communitys(city)
  if city == "birmingham"
    return BIRMINGHAM_COMMUNITIES
  elsif city == "nashville"
    return NASHVILLE_COMMUNITIES
  else
    return nil
  end
end

def load_suppliers(city)
  if city == "birmingham"
    return BIRMINGHAM_SUPPLIERS
  elsif city == "nashville"
    return NASHVILLE_SUPPLIERS
  else
    return nil
  end
end