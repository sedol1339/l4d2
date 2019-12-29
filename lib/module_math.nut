//---------- DOCUMENTATION ----------

/**
MATH FUNCTIONS
! requires lib/module_base !
------------------------------------
vector_to_angle(vec)
	Converts non-zero vector to QAngle (calculates pitch and yaw, roll is zero).
	Example: vector_to_angle(Vector(1, 1, 1)) //returns QAngle(-35.264389, 45, 0)
------------------------------------
angle_between_vectors(vec1, vec2)
	Calculates angle between two vectors in degrees.
	Example: angle_between_vectors(Vector(1, 0, 0), Vector(0, 1, 0)) //returns 90
------------------------------------
trace_line(start, end, mask = TRACE_MASK_VISIBLE_AND_NPCS, ignore = null)
	Performs a tracing using given params (see documentation of default TraceLine function), returns a table with results. If trace starts in solid, sets fraction to 0. Also calculates hit position and adds it to table as "hitpos".
	Example: logt(trace_line(Ent(1).EyePosition(), Vector(0, 0, 0), TRACE_MASK_ALL, Ent(1))) //"logt" requires kapkan/lib/strings
	Output:
		table: 
			"start": Vector (2111.03, 2764.26, 62.0313)
			"end": Vector (0, 0, 0)
			"pos": Vector (1787.05, 2340.03, 52.5114)
			"fraction": 0.153469
			"enthit": Entity (worldspawn #0)
			"startsolid": false
			"hitpos": Vector (1787.05, 2340.03, 52.5114)
			"ignore": Player (1 | kapkan)
			"mask": -1
			"hit": true
------------------------------------
normalize(vec)
	Returns a vector of same direction and length = 1, given non-zero vector.
------------------------------------
roundf(float)
	Rounds a float number to the nearest integer. For numbers greater than zero 0.5 is rounded up, for numbers less than zero 0.5 is rounded down.
	Example: roundf(0.5) //returns 1
	Example: roundf(-0.5) //returns -1
	Example: roundf(0.1) //returns 0
	Example: roundf(1/2) //returns 0, integer arithmetic 
	Example: roundf(1.0/2) //returns 1
------------------------------------
decompose_by_orthonormal_basis(vec, basis_x, basis_y, basis_z)
	Given a vector and parts of orthonormal basis, returns vector of coefficients in this basis.
------------------------------------
linear_interp(x1, y1, x2, y2, clump_left = false, clump_right = false)
	Constructs and returns a function that can be used to interpolate a value. This function works as follows:
	f(x1) = y1
	f(x2) = y2
	f(x) = <Y coord of point at line between (x1, y1) and (x2, y2) with given X coord>
	If clump_left is true, value less than min(x1,x2) treated as min(x1,x2)
	If clump_right is true, value less than max(x1,x2) treated as max(x1,x2)
	Example:
	local func = linear_interp(0, 0, 1, 100)
	f(0) //returns 0
	f(0.5) //returns 50
	f(1.5) //returns 150
------------------------------------
quadratic_interp(x1, y1, x2, y2, x3, y3, clump_left = false, clump_right = false)
	Same as linear_interp, but gets 3 points and uses parabola instead of straight line.
------------------------------------
bilinear_interp(x1, y1, x2, y2, x3, y3, clump_left = false, clump_right = false)
	Same as linear_interp, but gets 3 points and uses broken line instead of straight line.
------------------------------------
sliding_random(a_randomMin, a_randomMax, b_randomMin, b_randomMax, a_value, b_value, current_value)
	When we are in point A, random bounds are [a_rndMin, a_rndMax]. When we are in point B, random bounds are [b_rndMin, b_rndMax]. Let this bounds change linearly when we move from A to B. We calculate fraction based on a_val, cur_val and b_val and get random bounds, then we get random value between these bounds and return it.
 */

//---------- CODE ----------

this = ::root

log("[lib] including module_math")

vector_to_angle <- function(vec) {
	if (vec.x == 0 && vec.y == 0 && vec.z == 0) throw "cannot convect zero vector to angle";
	local dx = vec.x;
	local dy = vec.y;
	local dz = vec.z;
	local dxy = sqrt(dx*dx + dy*dy);
	local pitch = -57.2957795131*atan2(dz, dxy);
	local yaw = 57.2957795131*atan2(dy, dx);
	return QAngle(pitch, yaw, 0);
}

angle_between_vectors <- function(vec1, vec2) {
	local len1_sqr = vec1.LengthSqr()
	local len2_sqr = vec2.LengthSqr()
	if (len1_sqr == 0) throw "cannot find angle, vector 1 is zero";
	if (len2_sqr == 0) throw "cannot find angle, vector 2 is zero";
	local ang_cos = vec1.Dot(vec2) / sqrt(len1_sqr * len2_sqr);
	return 57.2957795131*acos(ang_cos);
}

trace_line <- function(start, end, mask = TRACE_MASK_VISIBLE_AND_NPCS, ignore = null) {
	local table = { start = start, end = end, mask = mask, ignore = ignore };
	TraceLine(table);
	if ("startsolid" in table) {
		if (table.startsolid) table.fraction = 0;
	} else {
		table.startsolid <- false
	}
	if (table.hit)
		table.hitpos <- table.start + (table.end - table.start).Scale(table.fraction);
	//DebugDrawLine_vCol(start, end, table.hit ? Vector(255,0,0) : Vector(0,255,0), false, 1);
	return table;
}

normalize <- function(vec) {
	local len = vec.Length()
	if (len == 0) throw "cannot normalize zero vector";
	return vec.Scale(1/len);
}

roundf <- function(a) {
	local a_abs = fabs(a)
	local a_abs_flr = floor(a_abs)
	local a_abs_part = a_abs - a_abs_flr
	local a_abs_round = a_abs_flr
	if (a_abs_part >= 0.5)
		a_abs_round++
	return (a > 0) ? a_abs_round : 0 - a_abs_round
}

decompose_by_orthonormal_basis <- function(vec, basis_x, basis_y, basis_z) {
	return Vector(vec.Dot(basis_x), vec.Dot(basis_y), vec.Dot(basis_z))
}

linear_interp <- function(x1, y1, x2, y2, clump_left = false, clump_right = false) {
	x1 = x1.tofloat()
	y1 = y1.tofloat()
	x2 = x2.tofloat()
	y2 = y2.tofloat()
	local a = (y2 - y1)/(x2 - x1)
	local b = y1 - a*x1
	local maxX = max(x1, x2)
	local minX = min(x1, x2)
	return function(x) {
		if (clump_left && x < minX) x = minX
		else if (clump_right && x > maxX) x = maxX
		return a*x + b
	}
}

quadratic_interp <- function(x1, y1, x2, y2, x3, y3, clump_left = false, clump_right = false) {
	x1 = x1.tofloat()
	y1 = y1.tofloat()
	x2 = x2.tofloat()
	y2 = y2.tofloat()
	x3 = x3.tofloat()
	y3 = y3.tofloat()
	local y2y3 = y2 - y3
	local y1y3 = y1 - y3
	local y1y2 = y1 - y2
	local x2x3 = x2 - x3
	local x1x3 = x1 - x3
	local x1x2 = x1 - x2
	local xDifs = x1x2*x1x3*x2x3
	local a = (x1*-y2y3 + x2*y1y3 + x3*-y1y2) / xDifs
	local b = (x1*x1*y2y3 + x2*x2*-y1y3 + x3*x3*y1y2) / xDifs
	local c = (x2*(x1*x1*y3-x3*x3*y1) + x2*x2*(x3*y1-x1*y3) + x1*x3*y2*-x1x3) / xDifs
	local maxX = max(x1, max(x2, x3))
	local minX = min(x1, min(x2, x3))
	return function(x) {
		if (clump_left && x < minX) x = minX
		else if (clump_right && x > maxX) x = maxX
		return a*x*x + b*x + c
	}
}

bilinear_interp <- function(x1, y1, x2, y2, x3, y3, clump_left = false, clump_right = false) {
	x1 = x1.tofloat()
	y1 = y1.tofloat()
	x2 = x2.tofloat()
	y2 = y2.tofloat()
	x3 = x3.tofloat()
	y3 = y3.tofloat()
	if (x1 >= x2 || x2 >= x3) throw "wrong x1 x2 x3"
	local a1 = (y2 - y1)/(x2 - x1)
	local b1 = y1 - a1*x1
	local a2 = (y3 - y2)/(x3 - x2)
	local b2 = y2 - a2*x2
	return function(x) {
		if (clump_left && x < x1) return y1
		if (x <= x2) return a1*x + b1
		if (clump_right && x > x3) return y3
		return a2*x + b2
	}
}

sliding_random <- function(a_randomMin, a_randomMax, b_randomMin, b_randomMax, a_value, b_value, current_val) {
	local fraction = (current_val - a_value) / (b_value - a_value)
	local current_randomMin = a_randomMin + (b_randomMin - a_randomMin) * fraction
	local current_randomMax = a_randomMax + (b_randomMax - a_randomMax) * fraction
	return RandomFloat(current_randomMin, current_randomMax)
}