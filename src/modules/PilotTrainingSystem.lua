--[[
	PilotTrainingSystem - Manages the complete pilot training pipeline
	Handles Ground School, Simulator, Training Flight, and Certification
	For Dreamlifter Airways
]]

local PilotTrainingSystem = {}

-- Training progress structure
PilotTrainingSystem.PlayerTrainingData = {}

-- Initialize training for a player
function PilotTrainingSystem:StartTraining(player, trainingAircraftID)
	local trainingData = {
		playerID = player.UserId,
		playerName = player.Name,
		aircraft = trainingAircraftID,
		startTime = os.time(),
		
		-- Stage completion tracking
		groundSchoolComplete = false,
		simulatorComplete = false,
		trainingFlightComplete = false,
		
		-- Exam scores
		groundSchoolScore = 0,
		practicalsScore = 0,
		finalExamScore = 0,
		
		-- Flight data
		flightHours = 0,
		landingScore = 0,
		emergencyHandling = 0,
		
		-- Status
		status = "GroundSchool", -- GroundSchool, Simulator, TrainingFlight, Exam, Certified, Failed
	}
	
	self.PlayerTrainingData[player.UserId] = trainingData
	return trainingData
end

-- Ground School Module
function PilotTrainingSystem:CompleteGroundSchool(playerID, examAnswers)
	local trainingData = self.PlayerTrainingData[playerID]
	if not trainingData then return false, "Training not found" end
	
	-- Calculate exam score (simplified - in real game, this would be more complex)
	local score = self:GradeExam(examAnswers)
	trainingData.groundSchoolScore = score
	
	if score >= 80 then
		trainingData.groundSchoolComplete = true
		trainingData.status = "Simulator"
		return true, "Ground School completed with score: " .. score .. "%"
	else
		trainingData.status = "Failed"
		return false, "Failed Ground School. Score: " .. score .. "%. Need 80%+ to pass."
	end
end

-- Simulator Training Module
function PilotTrainingSystem:CompleteSimulator(playerID, simulatorData)
	local trainingData = self.PlayerTrainingData[playerID]
	if not trainingData then return false, "Training not found" end
	if not trainingData.groundSchoolComplete then return false, "Must complete Ground School first" end
	
	-- Evaluate simulator performance
	local takeoffScore = simulatorData.takeoffQuality or 70
	local cruisingScore = simulatorData.cruisingStability or 70
	local landingScore = simulatorData.landingQuality or 70
	local emergencyScore = simulatorData.emergencyResponse or 70
	
	local averageScore = (takeoffScore + cruisingScore + landingScore + emergencyScore) / 4
	trainingData.practicalsScore = averageScore
	
	trainingData.simulatorComplete = true
	trainingData.status = "TrainingFlight"
	
	return true, "Simulator training completed. Overall score: " .. math.floor(averageScore) .. "%"
end

-- Training Flight
function PilotTrainingSystem:StartTrainingFlight(playerID)
	local trainingData = self.PlayerTrainingData[playerID]
	if not trainingData then return false, "Training not found" end
	if not trainingData.simulatorComplete then return false, "Must complete simulator first" end
	
	trainingData.flightStartTime = os.time()
	trainingData.trainingFlightInProgress = true
	
	return true, "Training flight in progress"
end

function PilotTrainingSystem:CompleteTrainingFlight(playerID, flightData)
	local trainingData = self.PlayerTrainingData[playerID]
	if not trainingData then return false, "Training not found" end
	
	-- Evaluate flight performance
	local takeoffQuality = flightData.takeoffQuality or 70
	local navigationAccuracy = flightData.navigationAccuracy or 70
	local landingQuality = flightData.landingQuality or 70
	local emergencyHandling = flightData.emergencyHandling or 70
	local crewCoordination = flightData.crewCoordination or 70
	
	local flightScore = (takeoffQuality + navigationAccuracy + landingQuality + emergencyHandling + crewCoordination) / 5
	trainingData.landingScore = landingQuality
	trainingData.emergencyHandling = emergencyHandling
	
	trainingData.flightHours = (os.time() - trainingData.flightStartTime) / 3600
	trainingData.trainingFlightComplete = true
	
	if flightScore >= 75 then
		trainingData.status = "Exam"
		return true, "Training flight completed. Flight score: " .. math.floor(flightScore) .. "%"
	else
		trainingData.status = "Failed"
		return false, "Flight evaluation failed. Score: " .. math.floor(flightScore) .. "%. Need 75%+ to pass."
	end
end

-- Final Certification Exam
function PilotTrainingSystem:CompleteCertificationExam(playerID, examAnswers)
	local trainingData = self.PlayerTrainingData[playerID]
	if not trainingData then return false, "Training not found" end
	if not trainingData.trainingFlightComplete then return false, "Must complete training flight first" end
	
	-- Grade final exam
	local examScore = self:GradeExam(examAnswers)
	trainingData.finalExamScore = examScore
	
	if examScore >= 80 then
		trainingData.status = "Certified"
		-- Calculate final certification score
		local certificationScore = (trainingData.groundSchoolScore * 0.25) + 
		                           (trainingData.practicalsScore * 0.25) + 
		                           (trainingData.landingScore * 0.25) + 
		                           (examScore * 0.25)
		
		return true, "CERTIFIED! Final certification score: " .. math.floor(certificationScore) .. "%"
	else
		trainingData.status = "Failed"
		return false, "Final exam failed. Score: " .. examScore .. "%. Need 80%+ to pass."
	end
end

-- Helper function to grade exam (simplified)
function PilotTrainingSystem:GradeExam(answers)
	-- In a real implementation, this would check against correct answers
	-- For now, return a score based on answer count and randomness
	if not answers or #answers == 0 then return 0 end
	
	-- Simulate grading (in production, compare with answer key)
	local correctCount = 0
	for _, answer in ipairs(answers) do
		if answer and answer ~= "" then
			correctCount = correctCount + 1
		end
	end
	
	return math.floor((correctCount / #answers) * 100)
end

-- Get training progress
function PilotTrainingSystem:GetTrainingProgress(playerID)
	return self.PlayerTrainingData[playerID]
end

-- Reset training (for player retries)
function PilotTrainingSystem:ResetTraining(playerID)
	self.PlayerTrainingData[playerID] = nil
	return true
end

-- Award certification
function PilotTrainingSystem:AwardCertification(playerID, aircraft)
	local trainingData = self.PlayerTrainingData[playerID]
	if not trainingData or trainingData.status ~= "Certified" then
		return false, "Player is not certified"
	end
	
	-- Award pilot rank and clearance
	return true, "Pilot certification awarded for " .. aircraft
end

return PilotTrainingSystem
