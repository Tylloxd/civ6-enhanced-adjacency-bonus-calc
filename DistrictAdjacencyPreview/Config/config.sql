-- =============================================================================
-- District Adjacency Preview Mod - Database Configuration
-- =============================================================================

-- This file sets up database queries and modifications needed for the 
-- District Adjacency Preview mod to access district information and 
-- adjacency rules from the game's database.

-- =============================================================================
-- DISTRICT TYPE QUERIES
-- =============================================================================

-- Create a view to easily access district types and their properties
CREATE VIEW IF NOT EXISTS DistrictAdjacencyPreview_Districts AS
SELECT 
    DistrictType,
    Name,
    PrereqTech,
    PrereqCivic,
    Coast,
    InternalOnly,
    ZOC,
    CaptureRemovesBuildings,
    PlunderType,
    PlunderAmount,
    TradeEmbark,
    TradeUnitRoute,
    OnePerCity,
    AllowsHolyCity,
    Maintenance,
    AirSlots,
    CitizenSlots,
    TravelTime,
    CityStrengthModifier,
    Housing,
    Entertainment,
    Appeal
FROM Districts;

-- =============================================================================
-- ADJACENCY BONUS QUERIES
-- =============================================================================

-- Create a view to access district adjacency bonuses
CREATE VIEW IF NOT EXISTS DistrictAdjacencyPreview_Adjacencies AS
SELECT 
    DistrictType,
    YieldChangeId,
    Description,
    YieldType,
    YieldChange,
    TilesRequired,
    AdjacentDistrict,
    AdjacentSeaResource,
    AdjacentFeature,
    AdjacentTerrain,
    AdjacentImprovement,
    AdjacentResource,
    AdjacentRiver,
    ObsoleteTech,
    ObsoleteCivic,
    RequiresPopulation,
    RequiredFeature,
    PrereqTech,
    PrereqCivic
FROM District_Adjacencies;

-- =============================================================================
-- CIVILIZATION UNIQUE DISTRICT QUERIES
-- =============================================================================

-- Create a view to access civilization-specific district replacements
CREATE VIEW IF NOT EXISTS DistrictAdjacencyPreview_UniqueDistricts AS
SELECT 
    CivilizationType,
    ReplaceDistrictType,
    DistrictType
FROM CivilizationTraits ct
JOIN Traits t ON ct.TraitType = t.TraitType
JOIN DistrictReplaces dr ON t.TraitType = dr.TraitType
WHERE t.TraitType LIKE '%TRAIT%';

-- =============================================================================
-- GOVERNMENT PLAZA ADJACENCY
-- =============================================================================

-- Government Plaza provides adjacency bonuses to most districts
-- This is handled in the Lua code but we can query the base data here
CREATE VIEW IF NOT EXISTS DistrictAdjacencyPreview_GovernmentPlaza AS
SELECT 
    'DISTRICT_GOVERNMENT' as SourceDistrict,
    DistrictType as TargetDistrict,
    1 as AdjacencyBonus
FROM Districts 
WHERE DistrictType IN (
    'DISTRICT_CAMPUS',
    'DISTRICT_THEATER',
    'DISTRICT_COMMERCIAL_HUB', 
    'DISTRICT_HARBOR',
    'DISTRICT_INDUSTRIAL_ZONE',
    'DISTRICT_HOLY_SITE'
);

-- =============================================================================
-- INFRASTRUCTURE DISTRICT BONUSES
-- =============================================================================

-- Special infrastructure districts that provide bonuses to other districts
CREATE VIEW IF NOT EXISTS DistrictAdjacencyPreview_Infrastructure AS
SELECT 
    InfrastructureDistrict,
    TargetDistrict,
    BonusAmount
FROM (
    SELECT 'DISTRICT_AQUEDUCT' as InfrastructureDistrict, 'DISTRICT_INDUSTRIAL_ZONE' as TargetDistrict, 2 as BonusAmount
    UNION ALL
    SELECT 'DISTRICT_DAM' as InfrastructureDistrict, 'DISTRICT_INDUSTRIAL_ZONE' as TargetDistrict, 2 as BonusAmount
    UNION ALL
    SELECT 'DISTRICT_CANAL' as InfrastructureDistrict, 'DISTRICT_INDUSTRIAL_ZONE' as TargetDistrict, 2 as BonusAmount
    UNION ALL
    SELECT 'DISTRICT_CANAL' as InfrastructureDistrict, 'DISTRICT_COMMERCIAL_HUB' as TargetDistrict, 1 as BonusAmount
    UNION ALL
    SELECT 'DISTRICT_CANAL' as InfrastructureDistrict, 'DISTRICT_HARBOR' as TargetDistrict, 1 as BonusAmount
);

-- =============================================================================
-- DEBUGGING AND TESTING QUERIES
-- =============================================================================

-- Query to check all available districts (for debugging)
-- SELECT * FROM DistrictAdjacencyPreview_Districts ORDER BY DistrictType;

-- Query to check adjacency rules (for debugging)
-- SELECT * FROM DistrictAdjacencyPreview_Adjacencies WHERE AdjacentDistrict IS NOT NULL ORDER BY DistrictType, AdjacentDistrict;

-- Query to check unique districts (for debugging)
-- SELECT * FROM DistrictAdjacencyPreview_UniqueDistricts ORDER BY CivilizationType; 