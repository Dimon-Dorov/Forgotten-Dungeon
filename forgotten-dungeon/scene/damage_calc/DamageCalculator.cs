using Godot;
using System.Collections.Generic;

public partial class DamageCalculator : Node
{
	public partial class DamageInfo : RefCounted
	{
		public float Damage { get; set; }
		public bool IsCrit { get; set; }
	}
	private const float K_DEFENSE_FACTOR = 19000.0f;
	
	public DamageInfo CalculateOutgoingDamage(float attackPower, float critChance, float critMultiplier)
	{
		var damageInfo = new DamageInfo { Damage = attackPower, IsCrit = false };
		if (GD.Randf() < critChance)
		{
			damageInfo.Damage = Mathf.Round(damageInfo.Damage * critMultiplier);
			damageInfo.IsCrit = true;
		}
		return damageInfo;
	}
	
	public float CalculateReceivedDamage(float incomingDamage, float targetDefense)
	{
		float defenseReduction = targetDefense / (targetDefense + K_DEFENSE_FACTOR);
		defenseReduction = Mathf.Min(defenseReduction, 0.75f);
		float finalDamage = incomingDamage * (1.0f - defenseReduction);
		return Mathf.Max(1.0f, Mathf.Round(finalDamage));
	}
}
