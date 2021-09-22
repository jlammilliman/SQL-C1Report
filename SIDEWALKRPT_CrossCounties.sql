IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SIDEWALKRPT_CrossCounties]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[SIDEWALKRPT_CrossCounties]
GO

-- =============================================
-- Author:		Justin Milliman
-- Create date: 8/2/2021
-- Updated: 8/2/2021
-- Description:	Generates the data for a Sidewalk 
-- segment on both sides of a road report.
--
-- =============================================

CREATE PROCEDURE [dbo].[SIDEWALKRPT_CrossCounties]
	@SidewalkID integer,
	@FWSegID integer

AS
BEGIN
	SET NOCOUNT ON;

		-- First Sidewalk
         SELECT s.ID, s.PRNo, s.BMP, s.EMP, s.FWSegID, sos.[Description] as SideOfStreet, s.[Length], s.Thickness, s.Width, a.FullName as SegmentName,
				s.Contractor, s.DateInstalled, s.Permit, rs.[Description] as RelationToStreet, om.[Description] as OwnerMaintainer, sm.[Description] as Material, 
				s.ParkwayWidth, s.ParkwayWidthUnits, s.WidthUnits, s.ThicknessUnits as ThiccUnits,
				CONVERT(varchar(75), scbr.[Description]) as StartCurbRamp, scrc.[Description] as StartRampCompliance,
				CONVERT(varchar(75), ecbr.[Description]) as EndCurbRamp, ecrc.[Description] as EndRampCompliance,
				CASE WHEN s.Side = -1 THEN 'Left' WHEN s.Side = 1 THEN 'Right' ELSE 'Unknown' END as Side
         FROM dbo.Sidewalk s
			INNER JOIN dbo.zlkSidewalk_RelationToStreet RS on rs.Code = s.RelationToStreetID
			INNER JOIN dbo.zlkSidewalk_SideOfStreet SOS on sos.Code = s.SideOfStreetID
			INNER JOIN dbo.zlkSidewalk_OwnerMaintainer OM on om.Code = s.OwnerMaintainerID
			INNER JOIN dbo.zlkSidewalk_Material SM on s.materialID = sm.Code
			INNER JOIN dbo.zlkSidewalk_CurbRamp scbr on scbr.Code = s.StartCurbRampID
			INNER JOIN dbo.zlkSidewalk_CurbRamp ecbr on ecbr.Code = s.EndCurbRampID
			INNER JOIN dbo.zlkSidewalk_ADACompliance scrc on scrc.Code = s.StartRampComplianceID
			INNER JOIN dbo.zlkSidewalk_ADACompliance ecrc on ecrc.Code = s.EndRampComplianceID
			INNER JOIN dbo.FW_FWSegMst F on s.FWSegID = f.ID
			INNER JOIN dbo.ROAD_Segment SEG on f.ID = seg.FWSegID
			INNER JOIN (SELECT alias.* FROM dbo.ROAD_Alias Alias WHERE alias.IsDefault = 1) A on seg.ID = a.SegmentID
		WHERE s.ID = @SidewalkID

		-- Second Sidewalk
         SELECT s.ID, s.PRNo, s.BMP, s.EMP, s.FWSegID, sos.[Description] as SideOfStreet, s.[Length], s.Thickness, s.Width, a.FullName as SegmentName,
				s.Contractor, s.DateInstalled, s.Permit, rs.[Description] as RelationToStreet, om.[Description] as OwnerMaintainer, sm.[Description] as Material, 
				s.ParkwayWidth, s.ParkwayWidthUnits, s.WidthUnits, s.ThicknessUnits as ThiccUnits,
				CONVERT(varchar(75), scbr.[Description]) as StartCurbRamp, scrc.[Description] as StartRampCompliance,
				CONVERT(varchar(75), ecbr.[Description]) as EndCurbRamp, ecrc.[Description] as EndRampCompliance,
				CASE WHEN s.Side = -1 THEN 'Left' WHEN s.Side = 1 THEN 'Right' ELSE 'Unknown' END as Side
         FROM dbo.FW_FWSegMst F
			INNER JOIN dbo.Sidewalk S on s.FWSegID = f.ID
			INNER JOIN dbo.zlkSidewalk_RelationToStreet RS on rs.Code = s.RelationToStreetID
			INNER JOIN dbo.zlkSidewalk_SideOfStreet SOS on sos.Code = s.SideOfStreetID
			INNER JOIN dbo.zlkSidewalk_OwnerMaintainer OM on om.Code = s.OwnerMaintainerID
			INNER JOIN dbo.zlkSidewalk_Material SM on s.materialID = sm.Code
			INNER JOIN dbo.zlkSidewalk_CurbRamp scbr on scbr.Code = s.StartCurbRampID
			INNER JOIN dbo.zlkSidewalk_CurbRamp ecbr on ecbr.Code = s.EndCurbRampID
			INNER JOIN dbo.zlkSidewalk_ADACompliance scrc on scrc.Code = s.StartRampComplianceID
			INNER JOIN dbo.zlkSidewalk_ADACompliance ecrc on ecrc.Code = s.EndRampComplianceID
			INNER JOIN dbo.ROAD_Segment SEG on seg.FWSegID = s.FWSegID
			INNER JOIN (SELECT alias.* FROM dbo.ROAD_Alias Alias WHERE alias.IsDefault = 1) A on seg.ID = a.SegmentID
		WHERE f.ID = @FWSegID AND s.ID != @SidewalkID AND s.FWSegID = @FWSegID

		-- First Sidewalk Side
		SELECT s.ID, CASE WHEN s.Side = -1 THEN 'Left' WHEN s.Side = 1 THEN 'Right' ELSE 'Unknown' END as Side FROM dbo.Sidewalk S WHERE s.ID = @SidewalkID

		-- First Inspection
		SELECT ISNULL(ic.[Description], 'Not Rated') as Condition, i.InspectDate, ISNULL(i.Inspector,'') as Inspector, 
			   ISNULL(i.Memo,'') as InspectionMemo, ia.Memo as iActivityMemo, ISNULL(iAct.[Description],'') as iActivityType, @SidewalkID as ID
		FROM (SELECT a.* FROM dbo.Sidewalk_Inspection a
	                        LEFT OUTER JOIN dbo.Sidewalk_Inspection b on a.SidewalkID=b.SidewalkID and a.InspectDate < b.InspectDate
						    WHERE b.SidewalkID IS NULL) I
			INNER JOIN dbo.Sidewalk_InspectionActivity IA on i.ID = ia.InspectionID
			INNER JOIN dbo.zlkSidewalk_Condition IC on ic.Code = i.ConditionID
			INNER JOIN dbo.zlkSidewalk_Activity IAct on iAct.Code = ia.ProposedActivityID
		WHERE I.SidewalkID = @SidewalkID
		ORDER BY i.InspectDate DESC

		-- First Work Order
		SELECT w.UserWorkOrderID as woID, ws.[Description] as woStatus, wa.[Description] as woActivity, 
				wr.[Description] as woReason, wop.[Description] as wPriority, wu.[Description] as woAuthorizedBy, 
				w.EnteredDate as woEnteredDate, w.[Description] as woDetails, w.WorkerComments as woComments, @SidewalkID as ID
		FROM (SELECT c.* FROM dbo.Sidewalk_WOSidewalk c
	                        LEFT OUTER JOIN dbo.Sidewalk_WOSidewalk d on c.SidewalkID=d.SidewalkID and c.WOItemID < d.WOItemID
						    WHERE d.SidewalkID IS NULL) WO
			INNER JOIN dbo.Sidewalk_WorkOrder W on W.ID = wo.WOItemID
			INNER JOIN dbo.zlkWO_Status WS on w.[Status] = ws.Code 
			INNER JOIN dbo.zlkSidewalk_WorkReason WR on w.WorkReasonID = wr.Code
			INNER JOIN dbo.zlkSidewalk_WorkAuthorization WU on w.WorkAuthID = wu.Code	
			INNER JOIN dbo.zlkSidewalk_Activity WA on wo.Activity = wa.Code	
			INNER JOIN zShared.WorkorderPriority WOP on wop.ID = w.woPriority
		WHERE wo.SidewalkID = @SidewalkID

		-- Second Sidewalk Side
		SELECT s.ID, CASE WHEN s.Side = -1 THEN 'Left' WHEN s.Side = 1 THEN 'Right' ELSE 'Unknown' END as Side 
		FROM dbo.FW_FWSegMst F
			INNER JOIN dbo.Sidewalk S on s.FWSegID = f.ID
		WHERE f.ID = @FWSegID AND s.ID != @SidewalkID

		-- Second Inspection
		SELECT ISNULL(ic.[Description], 'Not Rated') as Condition, i.InspectDate, ISNULL(i.Inspector,'') as Inspector, 
			   ISNULL(i.Memo,'') as InspectionMemo, ia.Memo as iActivityMemo, ISNULL(iAct.[Description],'') as iActivityType, s.ID
		FROM (SELECT a.* FROM dbo.Sidewalk_Inspection a
	                        LEFT OUTER JOIN dbo.Sidewalk_Inspection b on a.SidewalkID=b.SidewalkID and a.InspectDate < b.InspectDate
						    WHERE b.SidewalkID IS NULL) I
			INNER JOIN dbo.Sidewalk_InspectionActivity IA on i.ID = ia.InspectionID
			INNER JOIN dbo.zlkSidewalk_Condition IC on ic.Code = i.ConditionID
			INNER JOIN dbo.zlkSidewalk_Activity IAct on iAct.Code = ia.ProposedActivityID
			INNER JOIN dbo.FW_FWSegMst F on f.ID = @FWSegID
			INNER JOIN dbo.Sidewalk S on s.FWSegID = f.ID
		WHERE i.SidewalkID = s.ID AND s.FWSegID = @FWSegID AND i.SidewalkID != @SidewalkID
		ORDER BY i.InspectDate DESC

		-- Second Work Order
		SELECT w.UserWorkOrderID as woID, ws.[Description] as woStatus, wa.[Description] as woActivity, 
				wr.[Description] as woReason, wop.[Description] as wPriority, wu.[Description] as woAuthorizedBy, 
				w.EnteredDate as woEnteredDate, w.[Description] as woDetails, w.WorkerComments as woComments, s.ID
		FROM (SELECT c.* FROM dbo.Sidewalk_WOSidewalk c
	                        LEFT OUTER JOIN dbo.Sidewalk_WOSidewalk d on c.SidewalkID=d.SidewalkID and c.WOItemID < d.WOItemID
						    WHERE d.SidewalkID IS NULL) WO
			INNER JOIN dbo.Sidewalk_WorkOrder W on W.ID = wo.WOItemID
			INNER JOIN dbo.zlkWO_Status WS on w.[Status] = ws.Code 
			INNER JOIN dbo.zlkSidewalk_WorkReason WR on w.WorkReasonID = wr.Code
			INNER JOIN dbo.zlkSidewalk_WorkAuthorization WU on w.WorkAuthID = wu.Code	
			INNER JOIN dbo.zlkSidewalk_Activity WA on wo.Activity = wa.Code	
			INNER JOIN zShared.WorkorderPriority WOP on wop.ID = w.woPriority
			INNER JOIN dbo.FW_FWSegMst F on f.ID = @FWSegID
			INNER JOIN dbo.Sidewalk S on s.FWSegID = f.ID
		WHERE wo.SidewalkID = s.ID AND s.FWSegID = @FWSegID AND wo.SidewalkID != @SidewalkID

		-- First Obstructions
		SELECT CASE WHEN so.[Description] IS NULL THEN 'No' ELSE 'Yes' END as HasObstruction, ISNULL(so.[Description], 'No Obstructions') as ObstructionName,
				CASE WHEN s.Side = -1 THEN 'Left' WHEN s.Side = 1 THEN 'Right' ELSE 'Unknown' END as ObstructionSide
		FROM dbo.Sidewalk_Obstruction O 
			INNER JOIN dbo.zlkSidewalk_Obstruction SO on so.Code = o.ObstructionID
			INNER JOIN dbo.Sidewalk S on s.ID = @SidewalkID
		WHERE o.SidewalkID = s.ID AND s.FWSegID = @FWSegID

		-- Second Obstructions (Grabs from FWSegID instead of currentSidewalkID)
		SELECT CASE WHEN so.[Description] IS NULL THEN 'No' ELSE 'Yes' END as HasObstruction, ISNULL(so.[Description], 'No Obstructions') as ObstructionName,
				CASE WHEN s.Side = -1 THEN 'Left' WHEN s.Side = 1 THEN 'Right' ELSE 'Unknown' END as ObstructionSide
		FROM dbo.Sidewalk_Obstruction O 
			INNER JOIN dbo.zlkSidewalk_Obstruction SO on so.Code = o.ObstructionID
			INNER JOIN dbo.FW_FWSegMst F on f.ID = @FWSegID
			INNER JOIN dbo.Sidewalk S on s.FWSegID = f.ID
		WHERE o.SidewalkID = s.ID AND s.FWSegID = @FWSegID AND s.ID != @SidewalkID
END